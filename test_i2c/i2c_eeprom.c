/*
 * Copyright 2023 Watech Electronics
 * All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 */

/*!
 * \file i2c_eeprom.c
 * \brief I2C example file
 * \version 1.0.0
 */

/*******************************************************************************
 * Includes
 ******************************************************************************/
#include "board.h"
#include "hte_gpio.h"
#include "hte_i2c.h"
#include "hte_sysctrl.h"
#include <stdio.h>
/*******************************************************************************
 * Definitions
 ******************************************************************************/
/*! \brief Size of Transmission buffer */
#define TXBUFFERSIZE (ARRAY_SIZE(aTxBuffer) - 1)
/*! \brief Size of Reception buffer */
#define RXBUFFERSIZE (TXBUFFERSIZE)
/*! \brief I2C own address */
#define I2C_ADDRESS (0x60)
/*! \brief EEPROM address */
#define EEPROM_DEVICE_ADDR (0x50)
/*! \brief EEPROM page size */
#define EEPROM_PAGE_SIZE (256)
/*! \brief EEPROM start address to be written */
#define EEPROM_EXP_OFFSET (0)
/*******************************************************************************
 * Prototypes
 ******************************************************************************/
/* No Prototypes */

/*******************************************************************************
 * Variables
 ******************************************************************************/
/*! \brief Pointer to I2C handle */
I2C_Handle_t *pi2cHandle;
/*! \brief Buffer used for transmission */
uint8_t aTxBuffer[] = " ****Write and Read an I2C EEPROM****  ****Write and Read an I2C EEPROM****  ****Write and Read "
                      "an I2C EEPROM**** ";
/*! \brief Buffer used for reception */
uint8_t aRxBuffer[RXBUFFERSIZE];

/*******************************************************************************
 * Codes
 ******************************************************************************/

static void Error_Handler(void)
{
    printf("Error: entering Error_Handler()\n");
    while (1)
    {
        GPIO_togglePin(BOARD_GPIO_LED1);
        DELAY(100000);
    }
}

static void PrintBuffer(uint8_t *buf, uint16_t len)
{
    uint16_t i;
    for (i = 0; i < len; i++)
    {
        if ((i % 16) == 0)
        {
            printf("\n%04X: ", i);
        }
        printf("%02X ", buf[i]);
    }
    printf("\nASCII:");
    for (i = 0; i < len; i++)
    {
        char c = (buf[i] >= 32 && buf[i] < 127) ? (char)buf[i] : '.';
        putchar(c);
    }
    printf("\n");
}

static uint16_t Buffercmp(uint8_t *pBuffer1, uint8_t *pBuffer2, uint16_t BufferLength)
{
    while (BufferLength--)
    {
        if ((*pBuffer1) != *pBuffer2)
        {
            return BufferLength;
        }
        pBuffer1++;
        pBuffer2++;
    }

    return 0;
}

int main(void)
{
    BOARD_init();

    /* Pinmux configuration and Pad configuration */
    BOARD_ledPinConfig(0U);
    /* Configure LED GPIO as output */
    GPIO_setDirectionMode(BOARD_GPIO_LED1, kGPIO_DIR_OUTPUT);
    GPIO_writePin(BOARD_GPIO_LED1, 1);

    BOARD_i2cPinConfig(I2CA);

    BOARD_i2cClockEnable(I2CA);

    /* Configure the I2C peripheral */
    pi2cHandle                     = I2C_getHandle(kI2C_INDEX_A);
    pi2cHandle->instance           = I2CA;
    pi2cHandle->init.slaveAddr     = I2C_ADDRESS;
    pi2cHandle->init.speedMode     = kI2C_STANDARD_SPEED_MODE;
    pi2cHandle->init.addrMode      = kI2C_ADDR_MODE_7BITS;
    pi2cHandle->init.hcnt          = I2C_STANDARD_HCNT;
    pi2cHandle->init.lcnt          = I2C_STANDARD_LCNT;
    pi2cHandle->init.sdaRxHold     = 0x0;
    pi2cHandle->init.sdaTxHold     = 0x0;
    pi2cHandle->init.sdaSetup      = 0x64;
    pi2cHandle->init.noSdaRecovery = false;
    pi2cHandle->init.sdaTimeout    = 0xFFFFFFFF;
    pi2cHandle->init.sclTimeout    = 0xFFFFFFFF;
    pi2cHandle->mode               = kI2C_MASTER_MODE;
    pi2cHandle->targetAddr         = EEPROM_DEVICE_ADDR;

    if (I2C_initMaster(pi2cHandle) != kSTATUS_I2C_OK)
    {
        /* Processing Error */
        Error_Handler();
    }

    /* Put I2C peripheral in transmission process */
    /* Timeout is set to 10S  */
    printf("Writing %d bytes to EEPROM at offset %u\n", TXBUFFERSIZE, (unsigned)EEPROM_EXP_OFFSET);
    /* Timeout is set to 10S */
    if (I2C_eepromPageRead(pi2cHandle, EEPROM_EXP_OFFSET, kI2C_MEM_ADDR_SIZE_24BIT, aRxBuffer, TXBUFFERSIZE,
                           EEPROM_PAGE_SIZE, 10000) == kSTATUS_I2C_TIMEOUT)
    {
        /* Processing Error */
        Error_Handler();
    }

    printf("Read complete, %d bytes from EEPROM at offset %u\n", TXBUFFERSIZE, (unsigned)EEPROM_EXP_OFFSET);
    PrintBuffer(aRxBuffer, RXBUFFERSIZE);

    /* Turn LED2 off: Transfer in reception process is correct */
    GPIO_writePin(BOARD_GPIO_LED1, 1);

    /* Compare the sent and received buffers */
    if (Buffercmp((uint8_t *)aTxBuffer, (uint8_t *)aRxBuffer, RXBUFFERSIZE))
    {
        uint16_t i;
        for (i = 0; i < RXBUFFERSIZE; i++)
        {
            if (aTxBuffer[i] != aRxBuffer[i])
            {
                break;
            }
        }
        char wt = (aTxBuffer[i] >= 32 && aTxBuffer[i] < 127) ? (char)aTxBuffer[i] : '.';
        char rd = (aRxBuffer[i] >= 32 && aRxBuffer[i] < 127) ? (char)aRxBuffer[i] : '.';
        printf("Data mismatch at index %u: wrote 0x%02X('%c') read 0x%02X('%c')\n", (unsigned)i, aTxBuffer[i], wt,
               aRxBuffer[i], rd);
        printf("Wrote buffer:");
        PrintBuffer(aTxBuffer, RXBUFFERSIZE);
        printf("Read  buffer:");
        PrintBuffer(aRxBuffer, RXBUFFERSIZE);
        Error_Handler();
    }
    /* Infinite loop */
    while (1)
    {
    }
}PrintBuffer(aTxBuffer, TXBUFFERSIZE);
    if (I2C_eepromPageWrite(pi2cHandle, EEPROM_EXP_OFFSET, kI2C_MEM_ADDR_SIZE_24BIT, aTxBuffer, TXBUFFERSIZE,
                            EEPROM_PAGE_SIZE, 10000) != kSTATUS_I2C_OK)
    {
        /* Processing Error */
        Error_Handler();
    }

    printf("Write complete\n");

    /* Turn LED2 on: Transfer in transmission process is correct */
    GPIO_writePin(BOARD_GPIO_LED1, 0);
    DELAY(10000);

    /* Start the reception process */
    