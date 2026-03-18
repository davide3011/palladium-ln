"""
Palladium Lightning — automated regtest test suite.

Tests basic two-node LN functionality on Palladium regtest:
  - node startup and peer connectivity
  - channel opening and state
  - payments (both directions)
  - channel balance accounting
  - invoice expiry
  - cooperative channel close

Run:
    cd tests
    pytest test_palladium_regtest.py -v
    pytest test_palladium_regtest.py::test_basic_payment -v
    pytest test_palladium_regtest.py -v -n 2   # parallel
"""

import time

import pytest
from pyln.client import Millisatoshi, RpcError

from fixtures import *  # noqa: F401,F403
from utils import only_one, wait_for


# ---------------------------------------------------------------------------
# Shared fixture: two nodes connected with a funded channel
# ---------------------------------------------------------------------------

@pytest.fixture
def two_nodes(node_factory):
    """Two LN nodes connected and with an open, active channel (l1 → l2)."""
    l1, l2 = node_factory.line_graph(2, fundchannel=True, announce_channels=True)
    yield l1, l2


# ---------------------------------------------------------------------------
# 1. Node startup
# ---------------------------------------------------------------------------

def test_nodes_start(node_factory):
    """Both nodes start, connect and see each other as peers."""
    l1, l2 = node_factory.line_graph(2, fundchannel=False)

    i1 = l1.rpc.getinfo()
    i2 = l2.rpc.getinfo()

    assert i1['network'] == 'regtest'
    assert i2['network'] == 'regtest'
    assert i1['num_peers'] == 1
    assert i2['num_peers'] == 1
    assert i1['id'] != i2['id']


# ---------------------------------------------------------------------------
# 2. Channel state
# ---------------------------------------------------------------------------

def test_channel_opened(two_nodes):
    """Channel is in CHANNELD_NORMAL state with spendable capacity."""
    l1, l2 = two_nodes

    channels = l1.rpc.listpeerchannels()['channels']
    assert len(channels) == 1

    ch = only_one(channels)
    assert ch['state'] == 'CHANNELD_NORMAL'
    assert ch['spendable_msat'] > 0
    assert ch['peer_id'] == l2.info['id']


# ---------------------------------------------------------------------------
# 3. Basic payment l1 → l2
# ---------------------------------------------------------------------------

def test_basic_payment(two_nodes):
    """l1 pays a BOLT11 invoice created by l2."""
    l1, l2 = two_nodes

    inv = l2.rpc.invoice(100_000, 'basic', 'basic payment')['bolt11']
    result = l1.dev_pay(inv, dev_use_shadow=False)

    assert result['status'] == 'complete'
    assert result['destination'] == l2.info['id']

    invoice = only_one(l2.rpc.listinvoices('basic')['invoices'])
    assert invoice['status'] == 'paid'


# ---------------------------------------------------------------------------
# 4. Payment amount correctness
# ---------------------------------------------------------------------------

def test_payment_amount_correct(two_nodes):
    """The received amount matches exactly what was invoiced."""
    l1, l2 = two_nodes

    amount_msat = 50_000
    inv = l2.rpc.invoice(amount_msat, 'amount_check', 'amount test')['bolt11']
    result = l1.dev_pay(inv, dev_use_shadow=False)

    assert result['amount_msat'] == Millisatoshi(amount_msat)
    assert result['amount_sent_msat'] == Millisatoshi(amount_msat)  # no routing fees on direct channel


# ---------------------------------------------------------------------------
# 5. Channel balance after payment
# ---------------------------------------------------------------------------

def test_channel_balance_after_payment(two_nodes):
    """Paying decreases l1 spendable and increases l2 receivable."""
    l1, l2 = two_nodes

    before_l1 = only_one(l1.rpc.listpeerchannels()['channels'])['spendable_msat']
    before_l2 = only_one(l2.rpc.listpeerchannels()['channels'])['receivable_msat']

    amount_msat = 200_000
    inv = l2.rpc.invoice(amount_msat, 'balance', 'balance test')['bolt11']
    l1.dev_pay(inv, dev_use_shadow=False)

    # Wait for HTLC to settle
    wait_for(lambda: only_one(l1.rpc.listpeerchannels()['channels'])['htlcs'] == [])

    after_l1 = only_one(l1.rpc.listpeerchannels()['channels'])['spendable_msat']
    after_l2 = only_one(l2.rpc.listpeerchannels()['channels'])['receivable_msat']

    assert after_l1 < before_l1
    assert after_l2 < before_l2  # l2 can now receive less (used capacity)


# ---------------------------------------------------------------------------
# 6. Reverse payment l2 → l1
# ---------------------------------------------------------------------------

def test_payment_reverse(two_nodes):
    """l2 can pay l1 using an explicit route (bypasses gossip discovery)."""
    l1, l2 = two_nodes

    # Push 200k sat (200_000_000 msat) from l1 to l2 so l2 can pay back
    inv_push = l2.rpc.invoice(200_000_000, 'push', 'push balance')['bolt11']
    l1.dev_pay(inv_push, dev_use_shadow=False)
    wait_for(lambda: only_one(l1.rpc.listpeerchannels()['channels'])['htlcs'] == [])

    # Build an explicit route l2 → l1 using the direct channel (no gossip needed)
    amount_msat = 100_000_000  # 100k sat
    inv = l1.rpc.invoice(amount_msat, 'reverse', 'reverse payment')
    ch = only_one(l2.rpc.listpeerchannels()['channels'])
    route = [{
        'id': l1.info['id'],
        'channel': ch['short_channel_id'],
        'direction': ch['direction'],
        'amount_msat': amount_msat,
        'delay': 10,
        'style': 'tlv',
    }]
    l2.rpc.sendpay(route, inv['payment_hash'], payment_secret=inv['payment_secret'])
    result = l2.rpc.waitsendpay(inv['payment_hash'])

    assert result['status'] == 'complete'
    assert only_one(l1.rpc.listinvoices('reverse')['invoices'])['status'] == 'paid'


# ---------------------------------------------------------------------------
# 7. Invoice expiry
# ---------------------------------------------------------------------------

def test_invoice_expiry(two_nodes):
    """An expired invoice cannot be paid."""
    l1, l2 = two_nodes

    inv = l2.rpc.invoice(10_000, 'expired', 'expires fast', expiry=1)['bolt11']
    time.sleep(2)

    with pytest.raises(RpcError, match=r'[Ee]xpir'):
        l1.rpc.pay(inv)


# ---------------------------------------------------------------------------
# 8. Cooperative channel close
# ---------------------------------------------------------------------------

def test_cooperative_close(node_factory):
    """Cooperative close returns funds on-chain for both parties."""
    l1, l2 = node_factory.line_graph(2, fundchannel=True)

    # Confirm channel is open
    wait_for(lambda: only_one(l1.rpc.listpeerchannels()['channels'])['state'] == 'CHANNELD_NORMAL')

    # Send some funds to l2 so it has a balance to recover on close
    inv = l2.rpc.invoice(50_000_000, 'prefund', 'pre-close payment')['bolt11']
    l1.dev_pay(inv, dev_use_shadow=False)
    wait_for(lambda: only_one(l1.rpc.listpeerchannels()['channels'])['htlcs'] == [])

    # close() negotiates and broadcasts the closing tx
    l1.rpc.close(l2.info['id'])

    # Mine to confirm the closing tx (wait_for_mempool=1 waits for it to appear)
    l1.bitcoin.generate_block(100, wait_for_mempool=1)

    # Both nodes should have confirmed on-chain outputs
    wait_for(lambda: len([o for o in l1.rpc.listfunds()['outputs']
                          if o['status'] == 'confirmed']) > 0)
    wait_for(lambda: len([o for o in l2.rpc.listfunds()['outputs']
                          if o['status'] == 'confirmed']) > 0)
