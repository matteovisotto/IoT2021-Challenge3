
#include "Timer.h"
#include "Challenge3.h"
#include "printf.h"

module Challenge3C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  uint16_t rCounter = 0;
  uint8_t myId = 0;
  
  uint8_t led0 = 0;
  uint8_t led1 = 0;
  uint8_t led2 = 0;
  
  event void Boot.booted() {
  	myId = TOS_NODE_ID;
    call AMControl.start();
    printf("Booted\n");
    printf("Mote id: %u\n", TOS_NODE_ID);
    printfflush();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    uint16_t freq = 1000;
    if(myId == 2){
    	freq = 333;
    } else if(myId == 3){
    	freq = 200;
    }
    printf("Frequenza: %ld\n", freq);
    printfflush();
    call MilliTimer.startPeriodic(freq);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    counter++;
    if (locked) {
      return;
    }
    else {	
   
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return;
      }

      rcm->counter = counter;
      rcm->sender_id = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	dbg("ChallengeC", "Challenge3C: packet sent.\n", counter);	
	locked = TRUE;
      }
    }
  }

	uint8_t toggleLed(uint8_t status){
		if(status==0){
			return 1;
		}
		
		return 0;
	}
	
	void ledsOff() {
		led1 = 0;
		led2 = 0;
		led0 = 0;
	}

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
				   
    if (len != sizeof(radio_count_msg_t)){
    	return bufPtr;
    } else {
    	radio_count_msg_t* rcm = (radio_count_msg_t*) payload;
    	rCounter++;
    	printf("Sender ID: %u\n", rcm->sender_id);
    	printfflush();
    	if(rcm->sender_id == 1){
    		call Leds.led0Toggle();
    		led0 = toggleLed(led0);
    	} else if (rcm->sender_id == 2){
    		call Leds.led1Toggle();
    		led1 = toggleLed(led1);
    	} else if (rcm->sender_id == 3) {
    		call Leds.led2Toggle();
    		led2 = toggleLed(led2);
    	}
    	if(rCounter%10 == 0){
    		call Leds.led0Off();
    		call Leds.led1Off();
    		call Leds.led2Off();
    		ledsOff();
    	}
    	
    	if(myId == 2){
    		printf("%u%u%u\n", led2, led1, led0);
    		printfflush();
    	}
    	
    	return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




