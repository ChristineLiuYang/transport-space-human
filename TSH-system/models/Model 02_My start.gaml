/**
* Name: T-S-H_system
* Author: Liu Yang
* Description: 1st prototype of the model
* Tags: transport, urban space, pedestrians, urban design
*/

model prototype_TSH_system

global {
	file shape_file_landuse <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/landuse.shp");
	file shape_file_road <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/road.shp");
	
	file shape_file_bound <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/bound.shp");
	geometry shape <- envelope(shape_file_bound);
	
	float step <- 1 #mn;
	date starting_date <- date("2020-12-01-00-00-00");	
	
	int nb_people <- 10;
	
	int min_work_start <- 6;
	int max_work_start <- 9;
	int min_work_end <- 16; 
	int max_work_end <- 19; 
	
	int min_leisure_start <- 16;
	int max_leisure_start <- 19;
	int min_leisure_end <- 18; 
	int max_leisure_end <- 21; 
	
	float min_speed <- 15.0 #km / #h;
	float max_speed <- 30.0 #km / #h; 
	
	graph the_graph;
	
	init {
		create building from: shape_file_landuse with: [type::string(read ("TYPE"))] {
			if type="Residence" {
				color <- #yellow ;
			}
			if type="Work" {
				color <- #blue ;
			}
			if type="Leisure" {
				color <- #red ;
			}
		}
		create road from: shape_file_road ;
		
		list<building> residential_building <- building where (each.type="Residence");
		list<building> industrial_building <- building  where (each.type="Work") ;
		list<building> leisure_building <- building  where (each.type="Leisure") ;
		
		create people number: nb_people {
			speed <- rnd(min_speed, max_speed);
		
			living_place <- one_of(residential_building) ;
			location <- any_location_in (living_place);
			objective <- "rest";
			
			working_place <- one_of(industrial_building) ;
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			
			leisure_place <- one_of (leisure_building) ;
			start_leisure <- rnd (min_leisure_start, max_leisure_start) ;
			end_leisure <- rnd (min_leisure_end, max_leisure_end) ;
			
		}
	}
}

species building {
	string type;
	rgb color <- #gray ;
	
	aspect base {
		draw shape color: color ;
	}
}

species road  {
	rgb color <- #black ;
	
	aspect base {
		draw shape color: color ;
	}
}

species people skills:[moving] {
	rgb color <- #yellow ;
	building living_place <- nil ;
	building working_place <- nil ;
	building leisure_place <- nil ;
	int start_work ;
	int end_work  ;
	int start_leisure ;
	int end_leisure ;
	
	string objective ; 
	point the_target <- nil ;
		
	reflex time_to_work when: current_date.hour = start_work and objective = "rest"{
		objective <- "work" ;
		the_target <- any_location_in (working_place);
	}
	
	reflex time_to_leisure when: current_date.hour = start_leisure and objective = "work"{
		objective <- "play" ;
		the_target <- any_location_in (leisure_place);
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and objective = "play"{
		objective <- "rest" ;
		the_target <- any_location_in (living_place); 
	} 
	 
	reflex move when: the_target != nil {
		path path_followed <- goto(target:the_target, on:the_graph, return_path: false);
		
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base {
		draw circle(10) color: color border: #black;
	}
}

experiment road_traffic type: gui {
	parameter "Shapefile for the building:" var: shape_file_landuse category: "GIS" ;
	parameter "Shapefile for the road:" var: shape_file_road category: "GIS" ;
	parameter "Shapefile for the bound:" var: shape_file_bound category: "GIS" ;
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed" var: min_speed category: "People" min: 15 #km/#h ;
	parameter "maximal speed" var: max_speed category: "People" max: 30 #km/#h;
	
	output {
		display city_display type:opengl {
			species road aspect: base ;
			species building aspect: base ;
			species people aspect: base ;
		}
		display chart_display refresh: every(10#cycles) { 
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
				data "Work" value: people count (each.objective="work") color: #blue ;
				data "Leisure" value: people count (each.objective="play") color: #magenta ;
				data "Rest" value: people count (each.objective="rest") color: #yellow ;
			}
		}
	}
}