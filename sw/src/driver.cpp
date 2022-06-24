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

#include "driver.hpp"

const CGpioPins</* start: */ 0, /* count: */ 1>  CDriver::rwbPin        = CGpioPins</* start: */ 0, /* count: */ 1>();
const CGpioPins</* start: */ 1, /* count: */ 1>  CDriver::a15Pin        = CGpioPins</* start: */ 1, /* count: */ 1>();
const CGpioPins</* start: */ 2, /* count: */ 1>  CDriver::pendingbPin   = CGpioPins</* start: */ 2, /* count: */ 1>();
const CGpioPins</* start: */ 3, /* count: */ 1>  CDriver::donebPin      = CGpioPins</* start: */ 3, /* count: */ 1>();
const CGpioPins</* start: */ 4, /* count: */ 1>  CDriver::clkPin        = CGpioPins</* start: */ 4, /* count: */ 1>();
const CGpioPins</* start: */ 5, /* count: */ 15> CDriver::a0to14Pins    = CGpioPins</* start: */ 5, /* count: */ 15>();
const CGpioPins</* start: */ 20, /* count: */ 8> CDriver::dataPins      = CGpioPins</* start: */ 20, /* count: */ 8>();
