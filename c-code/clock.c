/*
 *  Author: John Callow
 *
 *  Code for a digital clock on a DE2-115 FPGA.  Currently you can set the time and alarm over jtag uart.
 *  If the alarm is on, all of the green lights will turn on when the time matches the alarm time.  The
 *  alarm time is displayed on the lcd screen while the current time is displayed on the seven segement
 *  displays.  Time can also be set using push buttons.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "alt_types.h"
#include "system.h"
#include "altera_avalon_lcd_16207.h"
#include "altera_avalon_lcd_16207_fd.h"
#include "altera_avalon_lcd_16207_regs.h"
#include "altera_avalon_jtag_uart_regs.h"
#include <sys/alt_irq.h>

/* Constant Definitions */
#define PIO_DATA_REG_OFT	0
#define PIO_DIRT_REG_OFT	1
#define PIO_INTM_REG_OFT	2
#define PIO_EDGE_REG_OFT	3

/* Macro definitions */
#define pio_read(base)			IORD(base, PIO_DATA_REG_OFT)
#define pio_write(base, data)	IOWR(base, PIO_DATA_REG_OFT, data);

/* Globals */

short _alarm_time;
char _alarm_on;

/* LCD functions */

/*  Appears broken
void lcd_set_cursor(int cursor_x, int cursor_y)
{
	FILE* fp;
	fp = fopen ("/dev/lcd_16207_0", "w");
    if (fp == NULL) {
    	fprintf(stderr, "open failed\n");
	}
    fprintf(fp, "\033[%u;%uH", cursor_y, cursor_x);
    fclose(fp);
}
*/
void lcd_clear_line(void)
{
	FILE* fp;
	fp = fopen ("/dev/lcd_16207_0", "w");
    if (fp == NULL) {
    	fprintf(stderr, "open failed\n");
	}
    fprintf(fp, "\033[K");
    fclose(fp);
}

void lcd_clear_screen(void)
{
	FILE* fp;
	fp = fopen ("/dev/lcd_16207_0", "w");
    if (fp == NULL) {
    	fprintf(stderr, "open failed\n");
	}
    fprintf(fp, "\033[2J");
    fclose(fp);
}

void lcd_print_alarm(short minutes, short hours)
{
	FILE* fp;
	fp = fopen ("/dev/lcd_16207_0", "w");
    if (fp == NULL) {
    	fprintf(stderr, "open failed\n");
	}
	fprintf(fp, "alarm %02u:%02u ", hours, minutes);
	fclose(fp);
}

/* Set Time */

void time_set(short hours, short minutes)
{
	short combine_times;
	combine_times = (hours << 7) | minutes;
	pio_write(CLOCK_SET_BASE, (combine_times | 0b0100000000000000));
	pio_write(CLOCK_SET_BASE, 0x0000);

}

int time_get(void)
{
	short temp_time = pio_read(CLOCK_GET_BASE);
	return temp_time;
}

/* Set Alarm Time */

void alarm_value(short minutes, short hours)
{
	_alarm_time = (hours << 7) | minutes;
}

void is_alarm_on(void)
{
	if (pio_read(SWITCH_BASE) & 0x0001)
	{
		_alarm_on = 1;
	}
	else
	{
		_alarm_on = 0;
	}
}

/* JTAG UART send */

void JTAG_send(char* message)
{
	FILE* fp;
		fp = fopen (JTAG_UART_NAME, "w");
	    if (fp == NULL) {
	    	fprintf(stderr, "open failed\n");
		}
		fprintf(fp, message);
		fclose(fp);
}

/*  Function currently not needed
int JTAG_read(char* message, int n)
{
	int c;
	c = IORD_ALTERA_AVALON_JTAG_UART_DATA(JTAG_UART_BASE);

	if (c & 0x00008000)
	{
		//length = (c >> 16);
		//printf("%i", length);
		//read = (char*)malloc(sizeof(char)*(length + 2));
		message[n] = (char)(c & 0x000000FF);
		for(i = 1; i <= length; i++)
		{
			c = IORD_ALTERA_AVALON_JTAG_UART_DATA(JTAG_UART_BASE);
			read[i] = (char)(c & 0x000000FF);
		}
		read[length + 1] = '\0';
		JTAG_send(read);
		free(read);
	}
	return 0;
}

*/

/* set time or alarm through uart state machine */

enum set_time_states {start, initial, wait, get_hour, set_hour, get_min, set_min, set} set_time_state;

int set_time(void)
{
	static char *endptr;
	static short hour;
	static short minute;
	static short recieved_char;
	static char set_ca;
	static int grab_char;
	static char message[3];
	static char buffer[20];

	switch(set_time_state)
	{
		case start:
			set_time_state = initial;
		break;

		case initial:
			set_time_state = wait;
			break;

		case wait:
			if ((set_ca == 0x61) || (set_ca == 0x63))
			{
				set_time_state = get_hour;
				recieved_char = 0;

			}
			else
			{
				set_time_state = wait;
			}
			break;

		case get_hour:
			if (recieved_char >= 2)
			{
				set_time_state = set_hour;
			}
			else if (recieved_char < 2)
			{
				set_time_state = get_hour;
			}
			break;

		case set_hour:
			if ((hour < 24)&&(hour >= 0)&&(*endptr == '\0'))
			{
				set_time_state = get_min;
			}
			else
			{
				set_time_state = get_hour;
			}
			break;

		case get_min:
			if (recieved_char >=2)
			{
				set_time_state = set_min;
			}
			else if (recieved_char < 2)
			{
				set_time_state = get_min;
			}
			break;

		case set_min:
			if ((minute < 60)&&(minute >= 0)&&(*endptr == '\0'))
			{
				set_time_state = set;
			}
			else
			{
				set_time_state = get_min;
			}
			break;

		case set:
			set_time_state = initial;
			break;

		default:
			set_time_state = start;
			break;
	}
	switch(set_time_state)
		{

			case start:
				break;

			case initial:
				recieved_char = 0;
				JTAG_send("press c to set clock, a to set alarm \n");
				hour = 0;
				minute = 0;
				set_ca = 0;
				grab_char = 0;
				break;

			case wait:
				grab_char = IORD_ALTERA_AVALON_JTAG_UART_DATA(JTAG_UART_BASE) & 0x000080FF;

				if (grab_char == 0x00008061)
				{
					set_ca = 'a';
					JTAG_send("give hour in form XX \n");
				}
				else if (grab_char == 0x00008063)
				{
					set_ca = 'c';
					JTAG_send("give hour in form XX \n");
				}

				break;


			case get_hour:
				grab_char = IORD_ALTERA_AVALON_JTAG_UART_DATA(JTAG_UART_BASE) & 0x000080FF;

				if ((grab_char & 0x00008000) && (grab_char != 0x0000800D))
				{
					message[recieved_char] = (char)(grab_char & 0x000000FF);
					recieved_char++;
				}

				break;

			case set_hour:
				hour = strtol(message, &endptr, 0);
				if ((hour < 24)&&(hour >= 0)&&(*endptr == '\0'))
				{
					JTAG_send("give minute in form XX \n");
				}
				else
				{
					JTAG_send("Invalid input, try again \n");
				}
				recieved_char = 0;
				break;

			case get_min:
				grab_char = IORD_ALTERA_AVALON_JTAG_UART_DATA(JTAG_UART_BASE) & 0x000080FF;

				if ((grab_char & 0x00008000) && (grab_char != 0x0000800D))
				{
					message[recieved_char] = (char)(grab_char & 0x000000FF);
					recieved_char++;
				}

				break;

			case set_min:
				minute = strtol(message, &endptr, 0);
				if ((minute < 60)&&(minute >= 0)&&(*endptr == '\0'))
				{
					// success
				}
				else
				{
					JTAG_send("Invalid input, try again \n");
				}
				recieved_char = 0;
				break;

			case set:
				if (set_ca == 'c')
				{
					time_set(hour, minute);
					sprintf(buffer, "Success! Setting clock to %02u:%02u \n", hour, minute);
					JTAG_send(buffer);
				}
				else if (set_ca == 'a')
				{
					//lcd_set_cursor(1,5);
					//lcd_clear_line();
					lcd_clear_screen();
					lcd_print_alarm(minute, hour);
					alarm_value(minute, hour);
					sprintf(buffer, "Success! Setting alarm to %02u:%02u \n", hour, minute);
					JTAG_send(buffer);
				}
				break;

			default:
				set_time_state = initial;
				break;
		}
	return 0;
}


enum alarm_states{ alarm_start, alarm_off, alarm_on } alarm_state;

void check_alarm(void)
{
	switch(alarm_state)
	{
	case alarm_start:
		alarm_state = alarm_off;
		break;

	case alarm_off:
		if ((_alarm_time == time_get() ) && (_alarm_on == 1))
		{
			alarm_state = alarm_on;
		}
		else
		{
			alarm_state = alarm_off;
		}
		break;

	case alarm_on:
		if (_alarm_on == 0)
		{
			alarm_state = alarm_off;
		}
		else
		{
			alarm_state = alarm_on;
		}
		break;

	default:
		alarm_state = alarm_start;
		break;
	}

	switch(alarm_state)
	{
	case alarm_start:
		break;

	case alarm_off:
		pio_write(LEDG_BASE, 0x00);
		is_alarm_on();
		break;

	case alarm_on:
		pio_write(LEDG_BASE, 0xFF);
		is_alarm_on();
		break;

	default:
		break;

	}
}

int main(){

	//initialize state machines and data
	_alarm_on = 0;
	set_time_state = start;
	lcd_clear_screen();
	alarm_value(0, 12);
	lcd_print_alarm(0, 12);
	time_set(0, 0);
	while(1){

	  set_time();
	  check_alarm();

  }
}



