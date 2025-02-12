/**
 * Number stuff
 *
 * License:
 *   This Source Code Form is subject to the terms of
 *   the Mozilla Public License, v. 2.0. If a copy of
 *   the MPL was not distributed with this file, You
 *   can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Authors:
 *   Vladimir Panteleev <vladimir@thecybershadow.net>
 */

module ae.utils.math;

public import std.algorithm : min, max, swap;
public import std.math;
import std.traits : Signed, Unsigned;
import core.bitop : bswap;

typeof(Ta+Tb+Tc) bound(Ta, Tb, Tc)(Ta a, Tb b, Tc c) { return a<b?b:a>c?c:a; }
bool between(T)(T point, T a, T b) { return a <= point && point <= b; } /// Assumes points are sorted (was there a faster way?)
auto sqr(T)(T x) { return x*x; }

void sort2(T)(ref T x, ref T y) { if (x > y) { T z=x; x=y; y=z; } }

T itpl(T, U)(T low, T high, U r, U rLow, U rHigh)
{
	return cast(T)(low + (cast(Signed!T)high-cast(Signed!T)low) * (cast(Signed!U)r - cast(Signed!U)rLow) / (cast(Signed!U)rHigh - cast(Signed!U)rLow));
}

byte sign(T)(T x) { return x<0 ? -1 : x>0 ? 1 : 0; }

int compare(T)(T a, T b)
{
	return a<b ? -1 : a>b ? 1 : 0;
}

auto op(string OP, T...)(T args)
{
	auto result = args[0];
	foreach (arg; args[1..$])
		mixin("result" ~ OP ~ "=arg;");
	return result;
}

auto sum(T...)(T args) { return op!"+"(args); }
auto average(T...)(T args) { return sum(args) / args.length; }

template unary(char op)
{
	T unary(T)(T value)
	{
		// Silence DMD 2.078.0 warning about integer promotion rules
		// https://dlang.org/changelog/2.078.0.html#fix16997
		static if ((op == '-' || op == '+' || op == '~') && is(T : int))
			alias CastT = int;
		else
			alias CastT = T;
		return mixin(`cast(T)` ~ op ~ `cast(CastT)value`);
	}
}

/// Like the ~ operator, but without int-promotion.
alias flipBits = unary!'~';

unittest
{
	ubyte b = 0x80;
	auto b2 = b.flipBits;
	assert(b2 == 0x7F);
	static assert(is(typeof(b2) == ubyte));
}

T swapBytes(T)(T b)
{
	static if (b.sizeof == 1)
		return b;
	else
	static if (b.sizeof == 2)
		return cast(T)((b >> 8) | (b << 8));
	else
	static if (b.sizeof == 4)
		return bswap(b);
	else
		static assert(false, "Don't know how to bswap " ~ T.stringof);
}

bool isPowerOfTwo(T)(T x) { return (x & (x-1)) == 0; }
T roundUpToPowerOfTwo(T)(T x) { return nextPowerOfTwo(x-1); }
T nextPowerOfTwo(T)(T x)
{
	x |= x >>  1;
	x |= x >>  2;
	x |= x >>  4;
	static if (T.sizeof > 1)
		x |= x >>  8;
	static if (T.sizeof > 2)
		x |= x >> 16;
	static if (T.sizeof > 4)
		x |= x >> 32;
	return x + 1;
}

/// Integer log2.
ubyte ilog2(T)(T n)
{
	ubyte result = 0;
	while (n >>= 1)
		result++;
	return result;
}

unittest
{
	assert(ilog2(0) == 0);
	assert(ilog2(1) == 0);
	assert(ilog2(2) == 1);
	assert(ilog2(3) == 1);
	assert(ilog2(4) == 2);
}

/// Returns the number of bits needed to
/// store a number up to n (inclusive).
ubyte bitsFor(T)(T n)
{
	return cast(ubyte)(ilog2(n)+1);
}

unittest
{
	assert(bitsFor( int.max) == 31);
	assert(bitsFor(uint.max) == 32);
}
