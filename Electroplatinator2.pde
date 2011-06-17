/*
  Micah's Electroplator MARK II, 
 
 This version is functionalized!
 
 Analog input, digital output
 
 Waits for a start signal, checks to see which mode it's in,
 and then runs the specified recipie and starts again
 
 The circuit:
 Inputs
 * D2: Half of toggle switch, indicates the simple on/off pulse mode
 * D3: Other half of toggle, indicates the fancy reverse polarity pulsing
 * D4: Start Button, activate the process
 * D5: E-stop
 Outputs
 * D7: Complex pulse on/off
 * D8: Complex pulse Direction
 * D6: Simple Pulse On/Off 
 * D9: Green Indicator (process running)
 * D10: Amber Indicator (process ready)
 * D11: Red Indicator (process killed (you broke something))
 * D12: Relay Activation (for Simple Pulse and Constant Current
 * D13: Fan activation
 
 Created by Micah Casteel
 02JUN2011
 
 Modified 
 17JUN2011
 
 This code is in the public domain. (or should be)
 */

//////////////////////////// Constants and Definitions ////////////////////////////
// These constants won't change.  They're used to give names
// to the pins used:

// Input Pins
const int ModeSimple       = 2;     // Select On/Off 
const int ModeDirectional  = 3;     //select Directional
const int Activate         = 4;     // Initiate Electroplatication
const int KillSwitch       = 5;     // Oh Shit something broke!  Turn it off!

//Output Pins
const int DirOnOff      = 6;   // Directional Pulse Pin
const int Dir           = 7;   // Directional Dir Pin
const int SimplePulse   = 8;   // Straight Pulse Pin
const int IndicatorGreen= 9;   // Green Indicator Light
const int IndicatorAmber= 10;  // Amber Indicator Light
const int IndicatorRed  = 11;  // Red Indicator Light
const int Relay         = 12;  // Relay
const int Fan           = 13;  // Fan

//miscellaneous flags, variables, etc...
boolean Reset = false;         // Reset Function
boolean Run   = false;         // Running Bool
boolean Kill  = false;         // Kill Switch bool 
long PulseOn = 0;              // Simple pulse on time
long PulseOff = 0;             // Simple pulse off time

//This section sets up the waveform parameters, these will
//be changed to the desired run parameters
long PlateDuration = 1; // Plating time duration (in minutes)
long   Period    = 100;  // Waveform period (ms)
float DutyCycle = 0.8;  // Percentage "on time" or "forward time"
long RunTime    = 0;    // Run time variable

//////////////////////////// Program Initialization ///////////////////////////////

void setup(){ 
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
  pinMode(Relay, OUTPUT);
  pinMode(Fan, OUTPUT);
  
  IndicatorSet(1, 0, 0);   //Initialize indicators
  digitalWrite(Fan, LOW); 
  digitalWrite(Relay, LOW);
  digitalWrite(SimplePulse, LOW); 
  digitalWrite(DirOnOff, LOW);
  digitalWrite(Dir, LOW); 

 
  //Perform initialization calcs 
  Period = 10 * (Period / 10); //  trim period to 10 millisecond intervals
  PlateDuration = Period*((PlateDuration * 60 * 1000)/Period); //conversion to milliseconds and chops off scrap
  PulseOn = Period * DutyCycle; // set on time variable
  PulseOff = Period - PulseOn; // set off time variable
}

//////////////////////////// Run Loop //////////////////////////////////////////////

void loop() {
  if (digitalRead(Activate)==HIGH){ //Has the Run button been depressed?
    Run = true; //Sets run flag
    IndicatorSet(0, 0, 1);   //Initialize indicators
    long x = 0; 
    if (digitalRead(ModeSimple)== HIGH){ //simple program
      digitalWrite(Relay, HIGH); 
      digitalWrite(Fan, HIGH); 
      for (RunTime = 0; RunTime <= PlateDuration; RunTime = RunTime + 10){
        if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          RunTime = PlateDuration;
        }
        else{
          x = SimplePulseFunction(x); 
        }
      }
      RunComplete();
    }    
    else if(digitalRead(ModeDirectional) == HIGH){    //directional program
      for (RunTime = 0; RunTime <= PlateDuration; RunTime = RunTime + 10){
        if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          RunTime = PlateDuration;
        }
        else{
          x = ModeDirectionalFunction(x);
        }
      } 
      RunComplete();
    }  
    else {      //only on program  
      delay(100);  
      digitalWrite(Relay, HIGH); 
      digitalWrite(Fan, HIGH); 
      delay(100); 
      for (RunTime = 0; RunTime < PlateDuration; RunTime = RunTime + 10){
        if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          RunTime = PlateDuration;
        }
        else {
          digitalWrite(SimplePulse,HIGH); 
          delay(10);
        }
      }
      RunComplete();
    }          
  } 
bailout:
  if (Kill == true  || digitalRead(KillSwitch)==HIGH){ //Did we get here by a kill switch signal?
    KillLoop();
  }
  delay(10);  //delay before running again             
  //rinse and repeat
}


//////////////////////////// Sub Function Set-up //////////////////////////////////

void IndicatorSet(boolean A,boolean R, boolean G){
  digitalWrite(IndicatorAmber, A); 
  digitalWrite(IndicatorRed, R);
  digitalWrite(IndicatorGreen, G);
}

void OutputSet(boolean Motor,boolean Direction,boolean Solid){
  digitalWrite(DirOnOff, Motor);
  digitalWrite(Dir, Direction);
  digitalWrite(SimplePulse, Solid);
}

long SimplePulseFunction(long x){
  if (x == 0){ //starting the pulse
    OutputSet(0,0,1);
    x = x + 10;          
    delay(10);
  }
  else if (x < PulseOn){ //starting the pulse
    x = x + 10;          
    delay(10);
  }         
  else if (x == PulseOn){
    OutputSet(0,0,0);
    x = x + 10;
    delay(10);
  }
  else if (x = Period){
    x = 0;
  }
  return x;
}

long ModeDirectionalFunction(long x){
  if (x == 0){ //starting the pulse forward
    OutputSet(1,1,0);
    x = x + 10;          
    delay(10);
  }
  else if (x < PulseOn){ //pulse running forward
    x = x + 10;          
    delay(10);
  }         
  else if (x == PulseOn){ //pulse direction switch
    OutputSet(1,0,0);
    x = x + 10;
    delay(10);
  }
  else if (x = Period){//pulse running backwards
    x = 0;
  }
  return x;
}

void RunComplete(){
  OutputSet(0,0,0); 
  digitalWrite(Relay, LOW);   
  digitalWrite(Fan, LOW);   
  Run = false; //Sets run flag
  if (Kill == true){
  }
  else{
    IndicatorSet(1, 0, 0);   //Initialize indicators
  }       
}

void KillLoop(){
  IndicatorSet(0,1,0);
  Reset = false;        //ensure reset is initialized
  //watch for reset  
  while (!Reset) {    //check for reset
    if (digitalRead(Activate)==HIGH && digitalRead(KillSwitch)==HIGH){   //double press and hold for reset
      Reset = true;
      IndicatorSet(1,1,1);                                                                         
      Kill = false;
    }
    else{
      delay(3000);   //pause before checking reset again
    } 
  }
  delay (5000);    // pause to ensure hands are off the button
  IndicatorSet(1, 0, 0);   //Reinitialize indicators
}                      // Reset complete 

