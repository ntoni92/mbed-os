/*
 * Copyright (c) 2019 STMicroelectronics. All Rights Reserved.
 *
 * The information contained herein is property of STMicroelectronics.
 * Terms and conditions of usage are described in detail in SOFTWARE
 * LICENSE AGREEMENT:
 *
 * (SLA0068 - PRODUCTION LIMITED LICENSE AGREEMENT FOR ST MATERIALS)
 *
 * You may obtain a copy of the License here:
 * LICENSE-SLA0068.txt and at STMicroelectronics website.
 *
 * THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
 * WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE
 * TIME. AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY
 * DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING
 * FROM THE CONTENT OF SUCH FIRMWARE AND/OR THE USE MADE BY CUSTOMERS OF THE
 * CODING INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
 *
 */

/*******************************************************************************
* Memory Definitions
*
* NOTE: The RAM region definition for mbed OS is intended starting with an offset
*       of VECTORS_SIZE with respect to the RAM base address (to copy the vector
*       table from the flash to the RAM in the M0 case, that doesn't have VTOR
*       register). In this linker script implementation the RAM region address
*       starts from the base address, to keep compatibility with the routines of
*       BLUENRGx, that requires some definitions in the vector table region.
*
*******************************************************************************/
/*
BlueNRG-2 memory map
+-----------------------+ 0x20005FFF
|  RAM (24K)            |
+-----------------------+ 0x20000000
|                       |
|                       |
+-----------------------+ 0x1003FFFF
|                       |
|  FLASH (256K)         |
+-----------------------+ 0x10040000
|                       |
+-----------------------| 0x100007FF
|   ROM (2K)            |
+-----------------------+ 0x10000000
*/

/* Device specific values */

#define FLASH_START   0x10040000
#define FLASH_SIZE    0x3FFFF      //256KB
//#define FLASH_END     0x1007FFFF
#define RAM_START     0x20000000
#define RAM_SIZE      0x6000       //24KB
//#define RAM_END       0x20005FFF
#define ROM_START     0x10000000
#define ROM_SIZE      0x800        //2KB
//#define ROM_END       0x100007FF

#define FLASH_APP_OFFSET 0
#define FLASH_NVM_DATASIZE (4*1024)
#define MEMORY_RAM_APP_OFFSET 0x2cc

#define VECTORS     48   /* This value must match NVIC_NUM_VECTORS */

/* Common - Do not change */

#if !defined(MBED_APP_START)
  #define MBED_APP_START (FLASH_START + FLASH_APP_OFFSET)
#endif

#if !defined(MBED_APP_SIZE)
  #define MBED_APP_SIZE (FLASH_SIZE - FLASH_NVM_DATASIZE - FLASH_APP_OFFSET)
#endif

/* Round up VECTORS_SIZE to 8 bytes */
//#define VECTORS_SIZE (((VECTORS * 4) + 7) & 0xFFFFFFF8)
#define VECTORS_SIZE (VECTORS*4)

MEMORY
{
    FLASH (rx)   	: ORIGIN = MBED_APP_START, LENGTH = MBED_APP_SIZE
    RAM (rwx)    	: ORIGIN = RAM_START, LENGTH = RAM_SIZE
    ROM(rx)			: ORIGIN = ROM_START, LENGTH = ROM_SIZE
    NVM (rx) 		: ORIGIN = FLASH_START + FLASH_SIZE + 1 - FLASH_NVM_DATASIZE, LENGTH = FLASH_NVM_DATASIZE
    BOOTLOADER (rx) : ORIGIN = FLASH_START, LENGTH = FLASH_APP_OFFSET
}

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */
ENTRY(RESET_HANDLER)

SECTIONS
{

  	/* The startup code goes first into FLASH */
  	.bootloader (ORIGIN(BOOTLOADER)) :
  	{
    	. = ALIGN(4);
    	KEEP(*(.bootloader)) /* Startup code */
    	. = ALIGN(4);
  	} > BOOTLOADER
  
  	.rom_info (NOLOAD) :
  	{
    	. = ALIGN(4);
    	KEEP(*(.rom_info)) 
    	. = ALIGN(4);
  	} > ROM
  
    /* The startup code goes first into FLASH */
/*
  	.intvec (ORIGIN(FLASH)) :
  	{
    	. = ALIGN(4);
    	KEEP(*(.intvec)) // Startup code
    	. = ALIGN(4);
  	} > FLASH
 */
 
    .text :
    {
		. = ALIGN(4);
		KEEP(*(.intvec)) /* Startup code */
    	KEEP(*(.cmd_call_table))
    	*(.text)           /* .text sections (code) */
    	*(.text*)          /* .text* sections (code) */
    	*(i.*)             /* i.* sections (code) */
    	*(.rodata)         /* .rodata sections (constants, strings, etc.) */
    	*(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    	*(.constdata)
    	*(.glue_7)         /* glue arm to thumb code */
    	*(.glue_7t)        /* glue thumb to arm code */

        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
         *crtbegin.o(.dtors)
         *crtbegin?.o(.dtors)
         *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
         *(SORT(.dtors.*))
         *(.dtors)

        *(.rodata*)

        KEEP(*(.eh_frame*))
    } > FLASH

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > FLASH

    __exidx_start = .;
    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > FLASH
    __exidx_end = .;


    
///////////////--BLUENRG2 requirements memory section start--///////////////
  /* used by the startup to initialize data */
  _sidata = LOADADDR(.data);
  /* used by the startup to initialize data */
  _sidata2 = LOADADDR(.ram_preamble);

  /* RAM preamble no init */
  .ram_preamble_noinit 0x20000000 (NOLOAD) :
  {
    . = ALIGN(4);
    . = 0x04 ; //There is a waste of RAM here
    KEEP(*(.ota_sw_activation))
  }  > RAM

/* RAM preamble initialized */
  .ram_preamble 0x20000008 /*(NOLOAD)*/ :
  {
    _sdata2 = .;        /* create a global symbol at data start */
    /* This is used by the startup in order to initialize the .bss section */
    KEEP(*(.savedMSP))
    . = 0x04 ;
    KEEP(*(.wakeupFromSleepFlag))
    . = 0x08 ;
    KEEP(*(.app_base))
    . = 0x0C ;
    KEEP(*(.flash_sw_lock))
    . = 0x28 ; 
    KEEP(*(.__blueflag_RAM))
      _edata2 = .;        /* create a global symbol at data end (.__crash_RAM is skipped since it must not be initialized) */
  }  > RAM AT> FLASH
  
      /* Location counter can end up 2byte aligned with narrow Thumb code but
       __etext is assumed by startup code to be the LMA of a section in RAM
       which must be 4byte aligned */
    __etext = ALIGN (4);

  /* RAM preamble no init */
  .ram_preamble_noinit2 0x20000034 (NOLOAD) :
  {
    KEEP(*(.__crash_RAM))
  }  > RAM
  /* Uninitialized data section */
   
  .bss.blueRAM 0x200000C0 :
  {
    . = ALIGN(4);
    _sbssblue = .;         // define a global symbol at .bss.blueRAM start
    KEEP(*(.bss.__blue_RAM))
    . = ALIGN(4);
    _ebssblue = .;         // define a global symbol at .bss.blueRAM end
    
    . = 0x20c + MEMORY_RAM_APP_OFFSET - 0x2cc;
    
  } > RAM
///////////////--BLUENRG2 requirements memory section end--///////////////

	.data : //AT (__etext)
    {
    	_sdata = .;        /* create a global symbol at data start */
        __data_start__ = .;
        *(vtable)
        *(.data*)

        . = ALIGN(4);
        /* preinit data */
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);

        . = ALIGN(4);
        /* init data */
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE_HIDDEN (__init_array_end = .);

        . = ALIGN(4);
        /* finit data */
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE_HIDDEN (__fini_array_end = .);

        KEEP(*(.jcr*))
        . = ALIGN(4);
        /* All data end */
        __data_end__ = .;
        _edata = .;        /* create a global symbol at data end */

    } > RAM AT> FLASH

	.bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* define a global symbol at bss start */
        __bss_start__ = .;
        *(.bss.ev_call_table)
    	*(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
        _ebss = .;         /* define a global symbol at bss end */
    } > RAM

    .heap (COPY):
    {
        __end__ = .;
        PROVIDE(end = .);
        *(.heap*);
        . = ORIGIN(RAM) + LENGTH(RAM); //antonio
        __HeapLimit = .;
    } > RAM 

    /* .stack_dummy section doesn't contains any symbols. It is only
     * used for linker to calculate size of stack sections, and assign
     * values to stack symbols later */
    .stack_dummy (COPY):
    {
        *(.stack*)
    } > RAM


///////////////--BLUENRG2 requirements memory section start--///////////////
  BLOCK_STACKLIB_FLASH_DATA (FLASH_START + FLASH_SIZE - FLASH_NVM_DATASIZE + 1) (NOLOAD) :
  {
    . = ALIGN(2048);
    
    KEEP(*(.noinit.stacklib_flash_data))
    KEEP(*(.noinit.stacklib_stored_device_id_data))
    
  } > NVM
///////////////BLUENRG2 requirements memory section end--///////////////


    /* Set stack top to end of RAM, and stack limit move down by
     * size of stack_dummy section */
     
    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    _estack = __StackTop;
    __StackLimit = __StackTop;  //antonio - SIZEOF(.stack_dummy);
    PROVIDE(__stack = __StackTop);

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")


  // Remove information from the standard libraries
  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
}