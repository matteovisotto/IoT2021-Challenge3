
#include "Timer.h"
#include "Challenge3.h"
 

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
  
  event void Boot.booted() {
  	myId = TOS_NODE_ID;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    uint8_t freq = 1000;
    if(myId == 2){
    	freq = 333;
    } else if(myId == 3){
    	freq = 200;
    }
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

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
				   
    if (len != sizeof(radio_count_msg_t)){
    	return bufPtr;
    } else {
    	radio_count_msg_t* rcm = (radio_count_msg_t*) payload;
    	rCounter++;
    	if(rcm->sender_id == 1){
    		call Leds.led0Toggle();
    	} else if (rcm->sender_id == 2){
    		call Leds.led1Toggle();
    	} else if (rcm->sender_id == 3) {
    		call Leds.led2Toggle();
    	}
    	if(rCounter%10 == 0){
    		call Leds.led0Off();
    		call Leds.led1Off();
    		call Leds.led2Off();
    	}
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




