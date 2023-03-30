// ===================================================================
// This is a library of clock generator cores, some with templates
// ===================================================================
// 
//  CSimpleClk       Generates a clock half the FPGA frequency
//
//  CPulseClk        Using a free running Counter (0 to 31), generates
//                   a clock pulse and an event at different times.
//
//  CGates           Using a free running Counter (0 to 99), generates 
//                   control signals: oGateReset and oGateRun.
//
//  CSimpleClk_T     Generates a clock at "FPGAfrequency / PERIOD".
//                   PERIOD is the template parameter.
//
//  CTimerClk_T      Generates a clock using the built-in timer.
//
//  CTwoPhasesClk_T  Generates a two phase clock.

//
// ===================================================================
// TEST BENCH:
//
//    - There is a single test bench project for all cores: main.rpj
//
// ===================================================================

// 
// Copyright ICI Techno 2016-2023, see LICENSE.
//
// ===================================================================


library ClockLib
{
    // -------------------------------------------------------------------
    // This core generates a clock half the FPGA frequency
    // -------------------------------------------------------------------
    component CSimpleClk(out passive bit oClk)
    {
        always()
        {
            oClk = !oClk;
        }
    };    
    
    // -------------------------------------------------------------------
    // This core generates a clock pulse and an event. It uses a free  
    //     running modulo 32 counter: loops from 0 to 31.
    //  
    //     - A pulse  is generated when the count is 31
    //     - An event is generated when the count is 15
    //
    // -------------------------------------------------------------------
    component CPulseClk(out passive bit oClkPulse,
                        out active  bit oClkEvent)
    {
        uint:5 Counter;
        
        start()
        {     
            Counter   = (uint:5)0;
            oClkPulse = 0t;
            oClkEvent = 0t;
        }
        
        always()
        {
            Counter++;
    
            oClkPulse = Counter == 31;  
    
            if(Counter == 15)
            {
                 oClkEvent :;
            }
        }
    };

    // -------------------------------------------------------------------
    // This core generates two gate signals. It uses a free  
    //     running modulo 100 counter: loops from 0 to 99.
    //  
    //     - The oGateReset in one between 5  and 10
    //     - The oGateRun   in one between 20 and 80
    //
    // -------------------------------------------------------------------
    component CGates(out passive bit oGateReset,
                     out passive bit oGateRun)
    {
        uint:7 Counter;
        
        start()
        {     
            Counter    = (uint:7)0;
            oGateReset = 0t;
            oGateRun   = 0t;
        }
        
        always()
        {
            Counter = (uint:7)((Counter >= 99)?(0):(Counter + 1));
    
            oGateReset = Counter >= 5  && Counter < 10;
            oGateRun   = Counter >= 20 && Counter < 80;
        }
    };
    
    // -------------------------------------------------------------------
    // This core template generates a clock using the built-in timer.  
    // The template parameter PERIOD is the clock period.
    //     Output frequency will be 1/PERIOD
    //  
    // -------------------------------------------------------------------
    template <int PERIOD>  // 
    component CTimerClk_T (out passive bit oClk)
    {
        start()
        {
            startTimer(PEDIOD - 1);
            oClk = 0t;
        }
    
        timerEnd()
        {
            oClk = !oClk;
            startTimer(PEDIOD - 1);
        }
    };    
    
    // -------------------------------------------------------------------
    // This core template generates a clock with a period specified by   
    //     the template parameter PERIOD. Output frequency will be 1/PERIOD.
    //     The parameter must be an event number larger or equal to 4.
    //     
    // -------------------------------------------------------------------
    template <int PERIOD>  
    component CSimpleClk_T(out passive bit oClk)
    {
        const int cHalfPeriod    = PERIOD/2;
        const int cSizeOfCounter = (int)ceil(log2((float)cHalfPeriod));
        
        uint:cSizeOfCounter Counter;
        
        start()
        {
            Counter = (uint:cSizeOfCounter)0;
            oClk = 0t;
        }

        always()
        {
            if(Counter == cHalfPeriod - 1)
            {
                Counter = (uint:cSizeOfCounter)0;
                oClk = !oClk;
            }
            else
            {
                Counter++;
            }
        }
    };
    

    // -------------------------------------------------------------------
    // This core template generates a two phase clock following this pattern:
    //    oClkPhase0     0011000000110000001100000011
    //    oClkPhase0     0000001100000011000000110000
    //
    //  The template paremeter PERIOD specifies the global period.
    //     The parameter must larger or equal to 8 and a multiple of 4.
    //     The clock frequency will be 1/PERIOD.
    //     
    // -------------------------------------------------------------------
    template <int PERIOD> 
    component CTwoPhasesClk_T(out passive bit oClkPhase0,
                              out passive bit oClkPhase1)
    {
        const uint cQuarterPeriod = PERIOD / 4;
        const uint cSizeOfCounter = (int)ceil(log2((float)cQuarterPeriod));
        
        uint:cSizeOfCounter Counter;
        uint:2 State;
        
        start()
        {     
            State      = (uint:2)0;
            Counter    = (uint:cSizeOfCounter)0;
            oClkPhase0 = 0t;
            oClkPhase1 = 0t;
        }
    
        always()
        {
            if(Counter == cQuarterPeriod - 1)
            {
                State++;
                Counter = 0;
                switch(State)
                { 
                    case 0: oClkPhase0 = 0; oClkPhase1 = 0;
                    case 1: oClkPhase0 = 1; oClkPhase1 = 0;
                    case 2: oClkPhase0 = 0; oClkPhase1 = 0;
                    case 3: oClkPhase0 = 0; oClkPhase1 = 1;
                }
            }
            else
            {
                Counter++;
            };
       }
    };
};

