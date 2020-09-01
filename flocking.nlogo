globals [max-IC;
  max-separate-turn;
  max-align-turn;
  max-cohere-turn;
  dead-bird;
  average-IC;
  IC
]


;;define predators(hawks) as a breed of turtles
breed [ predators predator ]

;;define preys(birds) as a breed of turtles
breed [ preys prey ]

predators-own [
  predators-speed ;;moving distance of predators
  predatormates ;;agentset of nearby predators
  attack-range ;;attack range to kill a bird
]

preys-own [
  flockmates         ;; agentset of nearby birds
  nearest-neighbor   ;; closest one of our flockmates
  birds-speed        ;; moving distance of birds
  interaction-count  ;; the total number of birds nearby at each time stamp
  average-speed      ;; average speed of a bird
  std                ;; standard deviation of speed
]

to setup
  clear-all
  set max-separate-turn 10
  set max-align-turn 20
  set max-cohere-turn 20
  create-preys initial-number-birds ;;create the preys, then initialize their variable
  [
    set color yellow - 1   ;; random shades look nice
    set size 1.5
    setxy random-xcor random-ycor
    set birds-speed 1.5
    set flockmates preys
    set interaction-count 0
    set max-IC [] ;;create list for storing maximum interaction count of birds
    set dead-bird [] ;;list to store all dead bird in order to count avg speed

  ]
  create-predators initial-number-predators ;;create the predators, then initialize their variable
  [
    set color red  ;;make predators easier to see
    set label-color blue
    set size 2 ;;make predators easier to see
    setxy random-xcor random-ycor
    set predators-speed 1.5
    set predatormates predators
    set attack-range predator-vision - 1
  ]
  display-labels
  reset-ticks
end

;; RUN-TIME PROCEDURES
;; main program control
to go
  if not any? preys [ stop ] ;;stop the model if there are no birds
  ask preys [
    set average-speed mean [birds-speed] of preys ;;update average speed of a bird
    if count preys > 1 ;;to make SD valid
      [set std standard-deviation [birds-speed] of preys] ;;update standard deviation of speed of a bird

    ifelse any? predators in-radius vision ;;if birds find any predators within vision then run away and flocking. otherwise, try to flock
    [
      set color yellow + 3
      run-away ;;birds turn around and run away from predators
      flock ;;birds seek for nearest flock
    ]
    [
      flock
      set color yellow - 2
    ]
    count-interaction
    ]
  ask predators[
    if cooperation?
      [check-collision] ;;check if there is any other predator nearby
    ifelse any? preys in-radius predator-vision   ;;if preys are found within vision then chasing, otherwise stay at the same position
    [
       kill-prey
        ;;when chasing for target the predators can fly with maximum allowed speed
       let target min-one-of preys [distance myself] ;;capture the closest prey as target
       if target != nobody
      [set heading (towards target)]  ;;move heading of predators towards the target]
       chase
    ]
    [
      wander
    ]
  ]
  set average-IC mean max-IC
  ;; the following line is used to make the turtles
  ;; animate more smoothly.
  repeat 5 [ ask preys [ fd birds-speed  / 5]  display]
  ;;ask preys [fd birds-speed  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;predators procedure;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to chase ;;found preys(birds) and move to hunt
  set predators-speed predator-maximum-speed
  fd predators-speed
end

to wander ;; the predators wander by slowly turning heading until preys (birds) are found
  ifelse (random 10 > random 10)  ;;randomly deciding turning left or right
  [lt random 30 ]   ;;do nothing but turning head to left
  [rt random 30 ]   ;;do nothing but turning head to right
end

to check-collision ;; the predators will avoid other predators
  find-predator ;;check if there is other predators within vision
  if any? predatormates
  [
    avoid-other-predator
  ]

end

to find-predator
  set predatormates other predators in-radius predator-vision
end

to avoid-other-predator
  let competitor min-one-of predatormates [distance myself] ;;define other predator as potential competitor
  set heading (towards competitor)
  rt 120
  fd predator-maximum-speed
end

to kill-prey ;;If a Prey is within attack range vision, kill the Prey
  let preys-around (preys in-radius attack-range)
  if any? preys-around
    [
      ask one-of preys-around [
        set dead-bird lput average-speed dead-bird ;; add avg to the list
        die] ;;force one bird to die if they are within the attack range of predators
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;birds procedure;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to run-away ;;birds start running away from predators
  let hawk min-one-of predators [distance myself] ;;define hawk as the most closest predator
  set heading (towards hawk) ;;set birds' heading towards the predator
  rt 180    ;;and then turn 180 degrees around so that the birds are able to run away from predators
  set birds-speed maximum-speed  ;;birds can fly with maximum allowed speed
end

to count-interaction
  set interaction-count count flockmates
  set IC interaction-count
  set max-IC lput interaction-count max-IC
  let max-ic-found max max-IC ;;find the maximum number of IC ever produced
end

to flock  ;; birds flocking procedure
  find-flockmates
  if any? flockmates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < 1.5
        [ separate ]
        [ align
          cohere ]
      ;; define emergent behaviour between birds
      ifelse max [birds-speed] of flockmates > birds-speed + 0.1 ;if bird B suddently moves faster because of predator
        [birds-speed-up]       ;;bird A will speed up
        [
          if birds-speed > minimum-speed
            [
              birds-speed-down
            ]
         ]
  ]
end

to birds-speed-up ; if
  if birds-speed < maximum-speed
  [set birds-speed birds-speed + 0.1]  ;;increase the speed of bird A
end

to birds-speed-down ;;otherwise reduce the speed
  set birds-speed birds-speed - 0.2
end


to find-flockmates  ;; birds procedure
  set flockmates other preys in-radius vision
end

to find-nearest-neighbor ;; birds procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

;; SEPARATE
to separate  ;; birds procedure
  if birds-speed > minimum-speed
    [ set birds-speed birds-speed - .1 ]
  turn-away ([heading] of nearest-neighbor) max-separate-turn
end

;;; ALIGN
to align  ;; birds procedure
  turn-towards average-flockmate-heading max-align-turn ;;birds are allowed to turn 50 degrees
end

to-report average-flockmate-heading  ;; turtle procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; COHERE
to cohere  ;; birds procedure
  turn-towards average-heading-towards-flockmates max-cohere-turn ;;birds are allowed to turn 50 degrees
end

to-report average-heading-towards-flockmates  ;; turtle procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

to display-labels
  ask preys [ set label "" ]
end

;; update the plot to collect IC data
to update-plot-IC
  set-current-plot "Interaction count of birds"
  clear-plot
  set-plot-x-range 0 count preys
  set-plot-y-range 0 count preys - 1
  plot-pen-reset
  foreach sort preys [[t] -> ask t [ plot interaction-count  ] ]
end

to update-plot-max-IC
  set-current-plot "Interaction count of birds"
  plot-pen-reset
  foreach sort preys [[t] -> ask t [
    if not empty? max-IC
    [plot max max-IC ]
  ] ]

end

to update-plot-speed
  set-current-plot "speed of birds"
  clear-plot
  set-plot-x-range 0 count preys
  set-plot-y-range 0 maximum-speed
  plot-pen-reset
  foreach sort preys [[t] -> ask t [ plot birds-speed  ] ]
end

to update-plot-max-IC-with-avg-speed
   set-current-plot "Interaction count of birds"
  plot-pen-reset
  foreach sort preys [[t] -> ask t [ plot average-speed  ] ]
end

to update-plot-standard-deviation
  set-current-plot "Avg speed & standard deviation for current birds"
  clear-plot
  set-plot-x-range 0 count preys
  set-plot-y-range 0 maximum-speed
  plot-pen-reset
  foreach sort preys [[t] -> ask t [ plot std  ] ]
end

to update-plot-average-speed
  set-current-plot "Avg speed & standard deviation for current birds"
  plot-pen-reset
  foreach sort preys [[t] -> ask t [ plot average-speed  ] ]
end

;; written by Rudong Su
;; based on code from Uri Wilensky, model library from Netlogo
