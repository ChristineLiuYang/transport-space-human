/**
* Name: T-S-H_system
* Author: Liu Yang
* Description: 1st prototype of the model
* Tags: transport, urban space, pedestrians, urban design
*/

model prototype_TSH_system

global {
	// load shape files and initialize graphs in GAMA
	file shape_file_landuse <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/landuse.shp");
	file shape_file_road <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/road.shp");
	file shape_file_node <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/node.shp");
	graph road_network ;
	
	file shape_file_bound <- file("/Users/Christine/GAMA/workspace1/TSH-system/includes/bound.shp");
	geometry shape <- envelope(shape_file_bound);
	
	// set up timings and steps
	float step <- 60 #mn;
	date starting_date <- date("2020-12-01-00-00-00");	
	
	// set up activity schedules
	int min_work_start <- 6;
	int max_work_start <- 9;
	int min_work_end <- 16; 
	int max_work_end <- 19; 
	
	int min_leisure_start <- 16;
	int max_leisure_start <- 19;
	int min_leisure_end <- 18; 
	int max_leisure_end <- 21; 
	
	// set up move speeds
	float min_speed <- 15.0 #km / #h;
	float max_speed <- 30.0 #km / #h; 
	
	// set up agent parameters 
	int AgentID <- 0 ;
	
	int SynPop <- 1;
	
	// initialization 
	init {
		// set up buildings environment, read parameters from the shape file, generate lists of different types of buidlings
		create building from: shape_file_landuse with: [
			ID::int(read("ID")),type::string(read ("TYPE")), area::int(read("AREA")), density::int(read("DENSITY")),
			res::int(read ("TYPE_RES")), ind::int(read ("TYPE_WOR")), leis::int(read ("TYPE_LEIS"))] {
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
		list<building> residential_building <- building where (each.type="Residence");
		list<building> industrial_building <- building  where (each.type="Work") ;
		list<building> leisure_building <- building  where (each.type="Leisure") ;
		
		// set up roads environment, generate a graph based on the shape file
		create road from: shape_file_road ;
		road_network <- as_driving_graph(road, roadNode) ;
		
		// set up roadNodes environment
		create roadNode from: shape_file_node ;
		
		// generate a synthetic population based on population density of the residential buildings 
		loop aBuilding over: residential_building {
			SynPop <- aBuilding.area * aBuilding.density * aBuilding.res / 50000; /* for presenting a sample of the population */
			if SynPop = 0 {
				SynPop <- 1 ;
			}
			
			// use the name "area" instead of "building"
			create people number: SynPop with: [location::any_location_in(aBuilding)] returns: List_of_Residents {
			    living_place <- aBuilding ;
		        working_place <- one_of(industrial_building) ;
			    leisure_place <- one_of (leisure_building) ;
			}
			
			// create 1 testing people agent for each area
			/* create people number: 1 with: [location::any_location_in(aBuilding)] returns: List_of_Residents {
			    living_place <- aBuilding ;
		        working_place <- one_of(industrial_building) ;
			    leisure_place <- one_of (leisure_building) ;
			}
			*/
			
			write "Residential building: " + aBuilding.ID + ", create Residents: " + length(List_of_Residents);
			loop aPeople over: List_of_Residents {
				write "This is resident: " + aPeople.getName(aPeople) ;
			}
		}
	}
}

// peoples agents
species people skills:[advanced_driving] {
	int id <- 0;
	
	rgb color <- #yellow ;
	building living_place <- nil ;
	building working_place <- nil ;
	building leisure_place <- nil ;
	
	int start_work ;
	int end_work ;
	int start_leisure ;
	int end_leisure ;
	
	string goal ; 
	point destination <- nil ;
	roadNode node_close_to_destination <- nil ;
	
	roadNode road_node ;
	path path_followed ;
	
	init {
		do setName ;
		speed <- rnd(min_speed, max_speed);
			    
		goal <- "rest";
			    
		start_work <- rnd (min_work_start, max_work_start);
		end_work <- rnd(min_work_end, max_work_end);
			    
		start_leisure <- rnd (min_leisure_start, max_leisure_start) ;
		end_leisure <- rnd (min_leisure_end, max_leisure_end) ;
			    
	}
	
	int setName {
		id <- AgentID +1 ;
		AgentID <- id ;
		return AgentID;
	}
	int getName(people aPeople) {
		return self.id ;
	}
	
	reflex time_to_work when: current_date.hour = start_work and goal = "rest"{
		goal <- "work" ;
		destination <- any_location_in (working_place);
	}
	
	reflex time_to_leisure when: current_date.hour = start_leisure and goal = "work"{
		goal <- "play" ;
		destination <- any_location_in (leisure_place);
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and goal = "play"{
		goal <- "rest" ;
		destination <- any_location_in (living_place); 
	} 
	
	path route_choice (point destination) {
		node_close_to_destination <- roadNode closest_to(destination) ;
		path_followed <- compute_path(graph: road_network, target: node_close_to_destination);
		return path_followed ;
	}
	
	reflex move when: destination != nil {
		path_followed <- route_choice(destination) ;
		do goto(target: destination, on: path_followed);
		
		if destination = location {
			destination <- nil ;
		}
	}
	
	aspect base {
		draw circle(10) color: color border: #black;
	}
}

// building agents
species building {
	int ID;
	string type;
	int res;
	int ind;
	int leis;
	
	int area;
	int density;
	
	rgb color <- #gray ;
	
	aspect base {
		draw shape color: color ;
	}
	
}

// road agents
species road skills:[skill_road] {
	rgb color <- #black ;
	
	aspect base {
		draw shape color: color ;
	}
}

// roadNode agents
species roadNode skills:[skill_road_node] {
	rgb color <- #red ;
	
	aspect base {
		draw shape color: color ;
	}
}

experiment road_traffic type: gui {
	parameter "Shapefile for the building:" var: shape_file_landuse category: "GIS" ;
	parameter "Shapefile for the road:" var: shape_file_road category: "GIS" ;
	parameter "Shapefile for the bound:" var: shape_file_bound category: "GIS" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed" var: min_speed category: "People" min: 15 #km/#h ;
	parameter "maximal speed" var: max_speed category: "People" max: 30 #km/#h;
	
	output {
		display city_display type:opengl refresh: every(10#cycles) {
			species road aspect: base ;
			species roadNode aspect: base ;
			species building aspect: base ;
			species people aspect: base ;
		}
		display chart_display refresh: every(10#cycles) { 
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
				data "Work" value: people count (each.goal="work") color: #blue ;
				data "Leisure" value: people count (each.goal="play") color: #magenta ;
				data "Rest" value: people count (each.goal="rest") color: #yellow ;
			}
			
		}
	}
}