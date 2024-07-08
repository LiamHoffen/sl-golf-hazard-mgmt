# sl-golf-hazard-mgmt
This repo is intended to provide useful code to all SL golf score card creators to help them identify hazards and make hazard play easier for golfers.


Initially, references will be identified where information related to hazards and hazard play are found
https://www.randa.org/en/rog/the-rules-of-golf/rule-17

https://collegiategolf.com/news/538-usga-rules-dropping-zones


Video of how hazards work
https://youtu.be/gfjY8G79MEI

Modules must be able to support  
- Reading course-owner definitions of hazard areas and drop zone definitions ** complete
- Compute if ball landed in a hazard and the point where it crossed into that hazard ** complete
- Compute safe locations from which to play for along the line, 2 club lengths and drop zones ** complete
- Must accomodate regions abutting regions, 2-region courses ** (must further develop)

Score cards must:
- Pass ball flight path to this module ** complete
- Receive info about hazards in play ** complete
- Request info for available relief from hazard ** complete
- Allow user to select the type of relief to apply for a hazard ** complete
- Allow next shot legally based upon proper use of relief ** (in development)


