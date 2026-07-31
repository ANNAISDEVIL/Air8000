/*
 * Copyright 2023 - 2024 Watech Electronics
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 * output HEX version
 */

/*!
 * \file hello_world.c
 * \brief Example of SDK debug console
 * \version 1.0.0
 */

/*******************************************************************************
 * Includes
 ******************************************************************************/
#include "board.h"
#include "hte_uart.h"
#include <stdio.h>
#include <string.h>

/*******************************************************************************
 * Definitions
 ******************************************************************************/
/*! \brief UART used by CPU1 in this example */
#define Air8000_UART (UARTC)
/*! \brief UART used by CPU2 in this example */
#define EXAMPLE_UART_CPU2 (UARTB)

/*! \brief UART used in this example */
#if defined(BOARD_USE_CPU1)
#define EXAMPLE_UART Air8000_UART
#elif defined(BOARD_USE_CPU2)
#define EXAMPLE_UART EXAMPLE_UART_CPU2
#endif

/*! \brief UART baudrate used in this example */
#define EXAMPLE_UART_BAUDRATE (115200U)
/*! \brief Clock of the UART used in this example */
#define EXAMPLE_UART_CLOCK BOARD_DEBUG_CONSOLE_CLOCK

/*******************************************************************************
 * Prototypes
 ******************************************************************************/
/* No Prototypes */

/*******************************************************************************
 * Variables
 ******************************************************************************/
///*! \brief UART example banner string */
//const uint8_t s_uartExampleString[] = "\r\n"
//                                      "UART Polling Example:\r\n"
//                                      "\tDevice will send each received character back\r\n"
//                                      "Please input:";
const uint8_t s_startMsg[] =
    "\r\n113B UARTC <-> Air8000 UART11 test start\r\n"
    "Baudrate: 115200, 8N1\r\n";

const uint8_t s_periodicMsg[] = "Hello Air8000 from 113B UARTC\r\n";
/*******************************************************************************
 * Codes
 ******************************************************************************/
int main(void)
{
    volatile uint32_t loopCount = 0;
    uint32_t txSeq = 0;
    char txBuf[64];
    int txLen = 0;
    /* Board initialization */
    /*
     * Note: In BOARD_init(), UARTA and UARTB is initialized for debug_console for CPU1 and CPU2.
     *       If the example uses the same UART, UART will be re-initialized in this example.
     */
    BOARD_init();

    /* Pinmux configuration and Pad configuration */
#if defined(BOARD_USE_CPU1)
    BOARD_uartPinConfig(Air8000_UART);
#endif
#if defined(BOARD_CONFIG_CPU2)
    BOARD_uartPinConfig(EXAMPLE_UART_CPU2);
    BOARD_uartAssign2CPU2(EXAMPLE_UART_CPU2);
#endif

    /* Peripheral clock configuration */
    BOARD_uartClockEnable(EXAMPLE_UART);

    UART_Config_t config;
    UART_getDefaultConfig(&config);
    config.baudRate = EXAMPLE_UART_BAUDRATE;

    (void)UART_init(EXAMPLE_UART, &config, EXAMPLE_UART_CLOCK);

//    /* Send the example banner */
//    (void)UART_writeDataBlocking(EXAMPLE_UART, s_uartExampleString, sizeof(s_uartExampleString));
    
    (void)printf("%s",s_startMsg);
    while (1)
    {
        loopCount++;
        if (loopCount >= 50000000U)
        {
           loopCount = 0;
            txSeq ++;
            
            txLen = snprintf(
                txBuf,
                sizeof(txBuf),
                "Hello Air8000 from 113B UARTC, seq =%lu\r\n",
                (unsigned long) txSeq
            );
            if  (txLen>0) {
                (void)UART_writeDataBlocking(
                EXAMPLE_UART,
                (const uint8_t *)txBuf,
                (uint32_t)txLen
                );
            }
        }
    }
}
