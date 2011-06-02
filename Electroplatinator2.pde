


void IndicatorSet(String A, String R, String G) {
    digitalWrite(IndicatorAmber, A); 
    digitalWrite(IndicatorRed, R);
    digitalWrite(IndicatorGreen, G);
}

void OutputSet(String DOO, String D, String SP){
    digitalWrite(DirOnOff,DOO);
    digitalWrite(Dir,D);
    digitalWrite(SimplePulse,SP);
}

void KillSwitch(){
    if (digitalRead(KillSwitch)==HIGH){
    Kill = true;
    goto bailout;
    }
    
void KillLoop(){
  IndicatorSet(LOW,HIGH,LOW);
  OutputSet(LOW,LOW,LOW);
  Reset = false;        //ensure reset is initialized
    //watch for reset  
    while (!Reset) {    //check for reset
      if (digitalRead(Activate)==HIGH && digitalRead(KillSwitch)==HIGH){   //double press and hold for reset
        Reset = true;
        IndicatorSet(HIGH,HIGH,HIGH);                                                                         
        Kill = false;
      }
      else{
        delay(3000);   //pause before checking reset again
      } 
    }
    delay (5000);      // pause to ensure hands are off the button
}                      // Reset complete 
