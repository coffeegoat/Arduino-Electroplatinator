/*
  Micah's Electroplator, 
 
 Analog input, digital output
 
 Waits for a start signal, checks to see which mode it's in,
 and then runs the specified recipie and starts again
 
 The circuit:
 Inputs
 * D12: Half of toggle switch, indicates the simple on/off pulse mode
 * D2: Other half of toggle, indicates the fancy reverse polarity pulsing
 * D3: Start Button, activate the process
 * D4: E-stop
 Outputs
 * D6: Simple Pulse On/Off 
 * D7: Complex pulse on/off
 * D8: Complex pulse Direction
 * D9: Green Indicator (process running)
 * D10: Amber Indicator (process ready)
 * D11: Red Indicator (process killed (you broke something))
 
 Created by Micah Casteel
 25MAY2011
 
 This code is in the public domain. (or should be)
 */

// These constants won't change.  They're used to give names
// to the pins used:
// Input Pins
const int ModeSimple = 12;  // Select On/Off 
const int ModeDirectional = 2; //select Directional
const int Activate   = 3;  // Initiate Electroplatication
const int KillSwitch = 4;  // Oh Shit something broke!  Turn it off!
//Output Pins
const int SimplePulse   = 6; // Straight Pulse Pin
const int DirOnOff      = 7; // Directional Pulse Pin
const int Dir           = 8; // Directional Dir Pin
const int IndicatorGreen= 9; // Green Indicator Light
const int IndicatorAmber= 10; // Amber Indicator Light
const int IndicatorRed  = 11; // Red Indicator Light
//miscellaneous flags, variables, etc...
boolean Reset = false;       // Reset Function
boolean Run   = false;       // Running Bool
boolean Kill  = false;       // Kill Switch bool 
long PulseOn = 0;            // Simple pulse on time
long PulseOff = 0;           // Simple pulse off time

//This section sets up the waveform parameters, these will
//be changed to the desired run parameters
long PlateDuration = 1; // Plating time duration (in minutes)
long   Period    = 100;  // Waveform period (ms)
float DutyCycle = 0.8;  // Percentage "on time" or "forward time"
long RunTime    = 0;    // Run time variable

void setup() {    
  //setup the pin roles
  pinMode(ModeSimple, INPUT);
  pinMode(ModeDirectional, INPUT);
  pinMode(Activate, INPUT);   
  pinMode(KillSwitch, INPUT);     
  pinMode(SimplePulse, OUTPUT);   
  pinMode(DirOnOff, OUTPUT);   
  pinMode(Dir, OUTPUT);   
  pinMode(IndicatorGreen, OUTPUT);   
  pinMode(IndicatorRed, OUTPUT);    
  pinMode(IndicatorAmber, OUTPUT);   

  //sets up indicator lights
  digitalWrite(IndicatorAmber, HIGH);
  digitalWrite(IndicatorGreen, LOW);
  digitalWrite(IndicatorRed, LOW);

  //Perform initialization calcs 
Period = 10 * (Period / 10); //  trim period to 10 millisecond intervals
PlateDuration = Period*((PlateDuration * 60 * 1000)/Period); //conversion to milliseconds and chops off scrap
PulseOn = Period * DutyCycle; // set on time variable
PulseOff = Period - PulseOn; // set off time variable

}
void loop() {
  if (digitalRead(Activate)==HIGH){ //Has the Run button been depressed?
    Run = true; //Sets run flag
    //set up indicator lights
    digitalWrite(IndicatorAmber, LOW); 
    digitalWrite(IndicatorRed, LOW);
    digitalWrite(IndicatorGreen, HIGH);
    long x = 0; 
    if (digitalRead(ModeSimple)== HIGH){ //simple program
        for (RunTime = 0; RunTime <= PlateDuration; RunTime = RunTime + 10){
          if (digitalRead(KillSwitch)==HIGH){
            Kill = true;
            goto bailout;
            }
          if (x == 0){ //starting the pulse
            digitalWrite(SimplePulse,HIGH);
            x = x + 10;          
            delay(10);
            }
          else if (x < PulseOn){ //starting the pulse
            x = x + 10;          
            delay(10);
            }         
          else if (x == PulseOn){
            digitalWrite(SimplePulse,LOW);
            x = x + 10;
            delay(10);
            }
          else if (x = Period){
            x = 0;
            }
        }
     digitalWrite(SimplePulse,LOW);         
    }    
    else if(digitalRead(ModeDirectional) == HIGH){    //directional program
        for (RunTime = 0; RunTime <= PlateDuration; RunTime = RunTime + 10){
          if (digitalRead(KillSwitch)==HIGH){
            Kill = true;
            goto bailout;
            }
          if (x == 0){ //starting the pulse forward
            digitalWrite(DirOnOff,HIGH);
            digitalWrite(Dir,HIGH);
            x = x + 10;          
            delay(10);
            }
          else if (x < PulseOn){ //pulse running forward
            x = x + 10;          
            delay(10);
            }         
          else if (x == PulseOn){ //pulse direction switch
            digitalWrite(Dir,LOW);
            x = x + 10;
            delay(10);
            }
          else if (x = Period){//pulse running backwards
            x = 0;
            }
        } 
        digitalWrite(DirOnOff,LOW);
        digitalWrite(Dir,LOW);
    }  
      else {      //only on program    
    for (RunTime = 0; RunTime < PlateDuration; RunTime = RunTime + 10){
        if (digitalRead(KillSwitch)==HIGH){
            Kill = true;
            goto bailout;
            }
        else {
          digitalWrite(SimplePulse,HIGH); 
          delay(10);
        }
    }
     digitalWrite(SimplePulse,LOW); 
        }          
     Run = false; //Sets run flag
    //set up indicator lights
    digitalWrite(IndicatorAmber, HIGH); 
    digitalWrite(IndicatorRed, LOW);
    digitalWrite(IndicatorGreen, LOW);  
  }
  else{    
  }  
bailout:
  if (Kill == true){ //Did we get here by a kill switch signal?
    //set up indicator lights
    Run = false;
    digitalWrite(DirOnOff,LOW);
    digitalWrite(Dir,LOW);
    digitalWrite(SimplePulse,LOW);
    digitalWrite(IndicatorAmber, LOW);
    digitalWrite(IndicatorGreen, LOW);
    digitalWrite(IndicatorRed, HIGH);
    Reset = false;
    //watch for reset  
    while (!Reset) { //check for reset
      if (digitalRead(Activate)==HIGH && digitalRead(KillSwitch)==HIGH){
        Reset = true;
        digitalWrite(IndicatorAmber, HIGH); 
        digitalWrite(IndicatorRed, HIGH);
        digitalWrite(IndicatorGreen, HIGH);
        delay(3000);                                                                                                    
        Kill = false;
      }
      else{
        delay(3000);
      } 
    }
    delay (3000); // pause
  }
  else{
  }
  digitalWrite(IndicatorAmber, HIGH); 
  digitalWrite(IndicatorRed, LOW);
  digitalWrite(IndicatorGreen, LOW);
  delay(10);  //delay before running again             
  //rinse and repeat
}

