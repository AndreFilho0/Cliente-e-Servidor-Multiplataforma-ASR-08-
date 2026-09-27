# Copyright (c) ZeroC, Inc.

# slice2py version 3.8.3

from __future__ import annotations
import IcePy

from Ice.UserException import UserException

from dataclasses import dataclass


@dataclass
class InvalidArgument(UserException):
    """
    Notes
    -----
        The Slice compiler generated this exception dataclass from Slice exception ``::Demo::InvalidArgument``.
    """
    reason: str = ""

    _ice_id = "::Demo::InvalidArgument"

_Demo_InvalidArgument_t = IcePy.defineException(
    "::Demo::InvalidArgument",
    InvalidArgument,
    (),
    None,
    (("reason", (), IcePy._t_string, False, 0),))

setattr(InvalidArgument, '_ice_type', _Demo_InvalidArgument_t)

__all__ = ["InvalidArgument", "_Demo_InvalidArgument_t"]
