#!/usr/bin/env python3
"""
This registers part of the Bitcoin backend methods.
We only use it for testing startup and we don't care about the actual values.
"""
import time

from pyln.client import Plugin


plugin = Plugin()


@plugin.method("estimatefees")
def getfeerate(plugin, **kwargs):
    time.sleep(1)
    return {}


@plugin.method("getrawblockbyheight")
def getblock(plugin, **kwargs):
    time.sleep(1)
    return {}


@plugin.method("getchaininfo")
def getchaininfo(plugin, **kwargs):
    time.sleep(1)
    return {}


# We don't use these options, but it allows us to get to the expected failure.
plugin.add_option("palladium-rpcuser", "", "")
plugin.add_option("palladium-rpcpassword", "", "")
plugin.add_option("palladium-rpcport", "", "")
plugin.add_option("palladium-datadir", "", "")

plugin.run()
