/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer and contributors.
 * 
 * https://github.com/DLehenbauer/commodore-pet-clone
 *
 * To the extent possible under law, I, Daniel Lehenbauer, have waived all
 * copyright and related or neighboring rights to this project. This work is
 * published from the United States.
 *
 * @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
 * @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors
 */

#include "pch.hpp"
#pragma once

#define DEFINE_ENUM_FLAG_OPERATORS(ENUMTYPE) \
inline ENUMTYPE operator | (ENUMTYPE a, ENUMTYPE b)     { return static_cast<ENUMTYPE>(static_cast<int>(a) | static_cast<int>(b)); } \
inline ENUMTYPE &operator |= (ENUMTYPE &a, ENUMTYPE b)  { return reinterpret_cast<ENUMTYPE&>(reinterpret_cast<int&>(a) |= static_cast<int>(b)); } \
inline ENUMTYPE operator & (ENUMTYPE a, ENUMTYPE b)     { return static_cast<ENUMTYPE>(static_cast<int>(a) & static_cast<int>(b)); } \
inline ENUMTYPE &operator &= (ENUMTYPE &a, ENUMTYPE b)  { return reinterpret_cast<ENUMTYPE&>(reinterpret_cast<int&>(a) &= static_cast<int>(b)); } \
inline ENUMTYPE operator ~ (ENUMTYPE a)                 { return static_cast<ENUMTYPE>(~static_cast<int>(a)); } \
inline ENUMTYPE operator ^ (ENUMTYPE a, ENUMTYPE b)     { return static_cast<ENUMTYPE>(static_cast<int>(a) ^ static_cast<int>(b)); } \
inline ENUMTYPE &operator ^= (ENUMTYPE &a, ENUMTYPE b)  { return reinterpret_cast<ENUMTYPE&>(reinterpret_cast<int&>(a) ^= static_cast<int>(b)); }
