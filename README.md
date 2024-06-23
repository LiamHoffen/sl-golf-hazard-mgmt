# sl-golf-hazard-mgmt
This repo is intended to provide useful code to all SL golf score card creators to help them identify hazards and make hazard play easier for golfers.


Initially, references will be identified where information related to hazards and hazard play are found
https://www.randa.org/en/rog/the-rules-of-golf/rule-17

https://collegiategolf.com/news/538-usga-rules-dropping-zones



Modules must be able to support  
- Reading course-owner definitions of hazard areas and drop zone definitions
- Compute if ball landed in a hazard and the point where it crossed into that hazard N.B.
- Compute safe locations from which to play for along the line, 2 club lengths and drop zones
- Must accomodate regions abutting regions, 2-region courses

Score cards must:
- Pass ball flight path to this module
- Receive info about hazards in play
- Request info for available relief from hazard
- Allow user to select the type of relief to apply for a hazard
- Allow next shot legally based upon proper use of relief


N.B. - module for computing in hazard area and point of crossing is now coded
