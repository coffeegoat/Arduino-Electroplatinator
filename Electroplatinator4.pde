/*
  Micah's Electroplator MARK IV, 
 
 This version is has upgraded time capabilities!
 
 Analog input, digital output
 
 Waits for a start signal, checks to see which mode it's in,
 and then runs the specified recipie and starts again
 
 The circuit:
 Inputs
 * D2: Half of toggle switch, indicates the fancy reverse polarity pulsing
 * D3: Other half of toggle, indicates the simple on/off pulse mode 
 * D4: Start Button, activate the process
 * D5: E-stop
 Outputs
 * D8:  Blue Indicator (process ready)
 * D9:  Green Indicator (process running)
 * D10: Red Indicator (process killed (you broke something))
 * D12: Forward Current
 * D13: Reverse Current

 Created by Micah Casteel
 02JUN2011
 
 Modified 
 03NOV2011
 
 This code is in the public domain. (or should be)
 */

//////////////////////////// Constants and Definitions ////////////////////////////
// These constants won't change.  They're used to give names
// to the pins used:

// Input Pins
const int ModeDirectional  = 2;     //select Directional
const int ModeSimple       = 3;     // Select On/Off 
const int Activate         = 4;     // Initiate Electroplatication
const int KillSwitch       = 5;     // Oh Shit something broke!  Turn it off!

//Output Pins
const int IndicatorBlue = 8 ;   // Blue Indicator Light
const int IndicatorGreen= 9;  //  Green Indicator Light
const int IndicatorRed  = 10;  // Red Indicator Light
const int Forward       = 11;   // Forward 
const int Reverse       = 12;   // Reverse
//miscellaneous flags, variables, etc...
boolean Reset = false;         // Reset Function
boolean Run   = false;         // Running Bool
boolean Kill  = false;         // Kill Switch bool 
long PulseOn = 0;              // Simple pulse on time
long PulseOff = 0;             // Simple pulse off time

//This section sets up the waveform parameters, these will
//be changed to the desired run parameters
long  PlateDurationMil = 7.5; // Plating time duration (in minutes)
long  PlateDuration = PlateDurationMil; //Variable Plate Duration
long  Period    = 1000;  // Waveform period (ms)
float DutyCycle = 0.5;  // Percentage "on time" or "forward time"
long  RunTime    = 0;    // Run time variable

//////////////////////////// Program Initialization ///////////////////////////////

void setup(){ 
  //setup the pin roles
  pinMode(ModeSimple, INPUT);                                                                
  pinMode(ModeDirectional, INPUT);
  pinMode(Activate, INPUT);   
  pinMode(KillSwitch, INPUT);     
  pinMode(Forward, OUTPUT);   
  pinMode(Reverse, OUTPUT);   
  pinMode(IndicatorGreen, OUTPUT);   
  pinMode(IndicatorRed, OUTPUT);    
  pinMode(IndicatorBlue, OUTPUT);   

  IndicatorSet(1, 0, 0);   //Initialize indicators
  OutputSet(0,0); //Initialize plater
  
 // Serial.begin(9600);
 
  //Perform initialization calcs 
 // Period = 10 * (Period / 10); //  trim period to 10 millisecond intervals
  PlateDurationMil = Period*((PlateDuration * 60 * 1000)/Period); //conversion to milliseconds and chops off scrap
  PulseOn = Period * DutyCycle; // set on time variable
  PulseOff = Period - PulseOn; // set off time variable    
}

//////////////////////////// Run Loop //////////////////////////////////////////////

void loop() {
  if (digitalRead(Activate)==HIGH){ //Has the Run button been depressed?
    Run = true; //Sets run flag
    IndicatorSet(0, 0, 1);   //Initialize indicators
    long StartTime = millis();
    PlateDuration = PlateDurationMil;
    if (digitalRead(ModeSimple)== HIGH){ //simple program
        SimplePulseMain(StartTime, PlateDuration);
      }    
      else if(digitalRead(ModeDirectional) == HIGH){    //directional program
        DirectionalMain(StartTime, PlateDuration); 
      }  
      else {      //only on program  
        ConstantMain(StartTime, PlateDuration);
      }          
  } 
bailout:
  if (Kill == true  || digitalRead(KillSwitch)==HIGH){ //Did we get here by a kill switch signal?
    KillLoop();
  }
///////////////////Debugging Help/////////////////  
//  Serial.println(Period);
//  Serial.println(PlateDuration);
//  Serial.println(PulseOn);
//  Serial.println(PulseOff);
///////////////////////////////
  delay(1000);  //delay before running again             
  //rinse and repeat
  
}


//////////////////////////// Sub Function Set-up //////////////////////////////////

void IndicatorSet(boolean B,boolean R, boolean G){
  digitalWrite(IndicatorBlue, B); 
  digitalWrite(IndicatorRed, R);
  digitalWrite(IndicatorGreen, G);
}

void OutputSet(boolean For,boolean Rev){
  digitalWrite(Forward, For);
  digitalWrite(Reverse, Rev);
}

void SimplePulseMain(long StartTime, long PlateDuration){
      while (millis() - StartTime < PlateDuration ){
        if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          PlateDuration = 0;
        }
        else{
          SimplePulseFunction(StartTime); 
         //Serial.println(RunTime);     debug help
         //Serial.println(x);           debug help 
        }
      }
      RunComplete();
}

void ConstantMain(long StartTime, long PlateDuration){    
      while (millis() - StartTime  < PlateDuration){
        if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          PlateDuration = 0;
        }
        else {
          OutputSet(1,0); 
        }
      }
      RunComplete();
}

void DirectionalMain(long StartTime, long PlateDuration){                              
      while (millis() - StartTime  < PlateDuration ){
      if (digitalRead(KillSwitch)==HIGH){
          Kill = true;
          PlateDuration = 0;
        }
        else{
         ModeDirectionalFunction(StartTime);
        }
      } 
      RunComplete();                                                                     
}    
  
void SimplePulseFunction(long StartTime){
  long Time = millis();
  long x = (Time-StartTime) % Period;  //establish period location from start time
  if (x <  PulseOn){ //pulse On
    OutputSet(1,0);
    }
  else{  //pulse Off
    OutputSet(0,0); 
    }
}

void ModeDirectionalFunction(long StartTime){
  long Time = millis();
  long x = (Time-StartTime) % Period; 
  if   (x <  PulseOn){           //Pulse Forward
    OutputSet(1,0);
    }
  else {
    OutputSet(1,1);          //pulse backwards
    }  
}

void RunComplete(){
  OutputSet(0,0);  
  Run = false; //Sets run flag
  if (Kill == true){
  }
  else{
    IndicatorSet(1, 0, 0);   //Initialize indicators
  }       
}

void KillLoop(){
  IndicatorSet(0,1,0);
  OutputSet(0,0);
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

