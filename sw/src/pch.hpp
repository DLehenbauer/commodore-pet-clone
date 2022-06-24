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

#ifndef __PCH_HPP__
#define __PCH_HPP__

#include <boost/asio/steady_timer.hpp>

#pragma GCC diagnostic push 
#pragma GCC diagnostic ignored "-Wparentheses"
#include <boost/lockfree/spsc_queue.hpp>
#pragma GCC diagnostic pop

#include <cassert>
#include <chrono>
#include <fcntl.h>
#include <fstream>
#include <functional>
#include <iostream>
#include <iterator>
#include <stdio.h>
#include <sys/mman.h>
#include <thread>
#include <unistd.h>
#include <vector>

#include <SDL2/SDL.h>

#endif // __PCH_HPP__