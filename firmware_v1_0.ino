/*
* Эффект радуги на ATTINY13
* Copyright (C) 2016 Алексей Шихарбеев
* http://samopal.pro
*/

#include <util/delay.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "light_ws2812.h"

// Количество светодиодов в ленте 1 - 16
#define num_pixel 6
#define STEP1 16
#define STEP2 2
#define button 0
#define TM 10
#define DX 2
//uint8_t TM = 10;
//uint8_t DX = 2;

struct cRGB led[num_pixel];
//uint8_t num_pixel = NUM_PIXEL;
bool effect = 0;
int main(void)
{
// Переменные для эффкта радуги
  uint8_t color = 0;
  pinMode(button, INPUT_PULLUP);
  attachInterrupt(button, x, FALLING);
  while(1)  {
// Цикл перебора пары цветов 0-5   
   if (effect == 0){
   for( int i=0; i< num_pixel; i++ ){
        Wheel(color + i*STEP1, i );
        ws2812_setleds(led,num_pixel);    
        color += STEP2;
        delay(TM);
   }
   }
   else{
    for( uint8_t i=0; i<6; i++)Mode1(TM,i);
   }
  }
} 

void x(){
  effect = !effect;
}

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
void Wheel(byte WheelPos,uint8_t n) {
  if(WheelPos < 85) {
     led[n].r = WheelPos * 3;
     led[n].g = 255 - WheelPos * 3;
     led[n].b = 0;
  } 
  else if(WheelPos < 170) {
     WheelPos -= 85;
     led[n].r = 255 - WheelPos * 3;
     led[n].g = 0;
     led[n].b = WheelPos * 3;
  } 
  else {
     WheelPos -= 170;
     led[n].r = 0;
     led[n].g = WheelPos * 3;
     led[n].b = 255 - WheelPos * 3;
  }
}

void Mode1(uint16_t wait, uint8_t pair){
   //uint8_t x = 1;
   //if( num_pixel > 8 ) x = 0;
// Метеор летит  
   for( uint8_t i1=0; i1<num_pixel; i1++ ){
// Чистим все    
      for( uint8_t i2=0; i2<num_pixel; i2++ )SetStarColor1(i2, 0, pair);
// Светодиод-ядро метеора      
      SetStarColor1(num_pixel-i1,15, pair);
// Хвост метеора      
      for( uint8_t i2=0; i2<i1; i2++ )SetStarColor1(num_pixel-i2-1, 16-(i1-i2)*DX, pair);
// Отобразить эффект и ждать паузу
      ws2812_setleds(led,num_pixel);    
      delay(wait);
   }
// Метеор пролетел, затухание хвоста   
   for( uint8_t i1=0; i1<num_pixel; i1++ ){
      for( uint8_t i2=0; i2<num_pixel; i2++ ){
         int c = 16-(i1-(i2-8))*2;
         if( c < 0 )c = 0;
         SetStarColor1(num_pixel-i2-1,c, pair);
      }
// Отобразить эффект и ждать паузу
      ws2812_setleds(led,num_pixel);
      delay(wait);
   }
}

/**
 * Разгорание одного пиксела на каждом луче 
 * @param n - Номер пиксела в луче 
 * @param br - Ярклсть
 * @param pair - Пара цветов 0-5
 * 
 */
void SetStarColor1( uint8_t n, uint8_t br, uint8_t pair){
   if( br > 15 )br=15;
   if( br < 8 ){
      switch( pair ){
        case 0 :
        case 3 :
           led[n].r = br*32;
           break;
        case 1 :
        case 4 :
           led[n].g = br*32;
           break;
        case 2 :
        case 5 :
           led[n].b = br*32;
           break;
      }
   }
   else {
      switch( pair ){
         case 0 :
            led[n].r = 255;
            led[n].g = (br-8)*32;
            break;
         case 1 :
            led[n].g = 255;
            led[n].b = (br-8)*32;
            break;
         case 2 :
            led[n].b = 255;
            led[n].r = (br-8)*32;
            break;
         case 3 :
            led[n].r = 255;
            led[n].b = (br-8)*32;
            break;
         case 4 :
            led[n].g = 255;
            led[n].r = (br-8)*32;
            break;
         case 5 :
            led[n].b = 255;
            led[n].g = (br-8)*32;
            break;
      }
   }

}

