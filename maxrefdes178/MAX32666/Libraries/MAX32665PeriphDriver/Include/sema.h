/**
 * @file    sema.h
 * @brief   Semaphore (SEMA) function prototypes and data types.
 */

/* ****************************************************************************
 * Copyright (C) 2016 Maxim Integrated Products, Inc., All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL MAXIM INTEGRATED BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Except as contained in this notice, the name of Maxim Integrated
 * Products, Inc. shall not be used except as stated in the Maxim Integrated
 * Products, Inc. Branding Policy.
 *
 * The mere transfer of this software does not imply any licenses
 * of trade secrets, proprietary technology, copyrights, patents,
 * trademarks, maskwork rights, or any other form of intellectual
 * property whatsoever. Maxim Integrated Products, Inc. retains all
 * ownership rights.
 *
 * $Date: 2018-09-11 00:20:17 +0300 (Tue, 11 Sep 2018) $
 * $Revision: 37771 $
 *
 *************************************************************************** */

/* Define to prevent redundant inclusion */
#ifndef _SEMA_H_
#define _SEMA_H_

/* **** Includes **** */
#include "mxc_config.h"
#include "mxc_sys.h"
#include "sema_regs.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup sema Semaphore (SEMA)
 * @ingroup periphlibs
 * @{
 */

/* **** Definitions **** */

/* **** Function Prototypes **** */

/**
 * @brief     Initialize the semaphore peripheral
 * @return    #E_NO_ERROR if semaphore acquired.
 */
int SEMA_Init(sys_cfg_sema_t * sys_cfg);

/**
 * @brief     Attempt to get a semaphore.
 * @param     sema   Number of semaphore you are trying to get.
 * @return    #E_NO_ERROR if semaphore acquired. 
 * @return    #E_BUSY if semaphore is already locked.
 */
int SEMA_GetSema(unsigned sema);

/**
 * @brief     Check a semaphore.
 * @param     sema   Number of semaphore you want to check.
 * @return    #E_NO_ERROR if semaphore is free. 
 * @return    #E_BUSY if semaphore is already locked.
 * @note      Will not be atomic if you call this function and then attempt to SEMA_GetSema().
 */
int SEMA_CheckSema(unsigned sema);

/**
 * @brief     Check all semaphores.
 * @return    Status of all semaphores. Each semaphore will be represented by 1 bit.
 * @note      Will not be atomic if you call this function and then attempt to SEMA_GetSema().
 */
uint32_t SEMA_Status(void);

/**
 * @brief     Frees the semaphore.
 * @param     sema   Number of semaphore want to free.
 */
void SEMA_FreeSema(unsigned sema);

/**
 * @brief     Shutdown the semaphore peripheral
 * @return    #E_NO_ERROR if semaphore acquired.
 */
int SEMA_Shutdown(void);



/**@} end of group sema */

#ifdef __cplusplus
}
#endif

#endif /* _SEMA_H_ */
