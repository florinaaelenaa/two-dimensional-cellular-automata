/*
 * Author:  Barbu Florina, 331AA
 *
 * Subject: Automat celular bidimensional
 *
 * Date: 27.11.2016
 */


`timescale 1ns / 1ps

`define read_cell			0
`define write_cell   	1
`define upt_done			2

module automaton(
    input               clk,            // synchronization signal
    input      [31:0]   rule,           // next generation rule; only used for bonus points
    output reg [5:0]    row,            // row index cell to be read/written
    output reg [5:0]    col,            // column index cell to be read/written
    output reg          world_we,       // write enable: 0 - cell is read, 1 - cell is written
    input               world_in,       // when reading: current cell value in world
    output reg          world_out,      // when writing: new cell value in world
    output reg          update_done);   // next generation was calculated; must be active for 1 clock cycle

	
	wire[31:0]       rule;
	reg [ 2:0]       state, next_state;
	reg [ 4:0]		  NVCES;
	integer 			  k;
	integer 			  buff_row;					 		//indexul liniei pe care o calculez din matricea lume
	integer 			  buff_col;
	
	reg  buffer[ 2:0][65:0];						 	//vector de citire pe care il consideram mereu bordat pe margini cu 0
																//dupa scrierea in lumea vectorului line, am grija sa shiftez mereu o linie in sus 				  
	
	initial begin
		state  		= `read_cell;		 				//starea initiala va fi de citire a primului element din lume
		row			= 1'b0;
		col			= 1'b0;
		
		buff_row	   = 1; 									//1 pt ca bordam prima linie a bufferului
		buff_col    = 0; 									
		
		update_done = 1'b0;
		world_we		= 1'b0;
		
		//bordarea marginilor vectorului de citire
		buffer[0][0]  = 1'b0;	buffer[1][0]  = 1'b0;   buffer[2][0]  = 1'b0;  //prima  coloana din buffer o setam pe 0
		buffer[0][65] = 1'b0;   buffer[1][65] = 1'b0;   buffer[2][65] = 1'b0;  //ultima coloana din buffer o setam pe 0
				
	end

	always @(posedge clk) 
	begin
	 case(state)

		`read_cell:
		begin
			
			//imi initialez prima linie din buffer-ul de citire cu 0
			if(row == 0 && col == 0)
			begin
				for(k = 1; k < 65; k = k + 1)
						buffer[0][k] = 1'b0;
				buff_col = 1;
			end
			
			buffer[buff_row][buff_col] = world_in; //salvam in buffer valoarea citita din world
			
			if(col < 63) 									//verific intai conditia ca in buffer s-a pus o linie
			begin			 									//compar cu 63, pt ca in interiorul conditiei mai incrementez o data pe ceas, deci mai primesc o val
				
				buff_col = buff_col + 1; 				//parcurgerea bufferului local nu se face pe ceas, dar incrementez indicele 
																//de coloana pentru a termina de stocat toata linia primita din world
				
				col = col + 1; 							//citim pe linie, deci incrementam doar indicele de coloana
				
				world_we = 1'b0;
				update_done = 1'b0;
				state = `read_cell; 						//raman in starea de citire pana termin de adus in buffer toata linia din world
			end
			else if(col == 63 && row == 0)         //inseamna ca eu mai am de adus din world si urmatoare linie deci raman in citire
			begin
				
				row = row + 1;     					   //trec la linia urmatoare din lume
				buff_row = buff_row + 1;            //trec la urmatoarea linie din bufferul local
				  
				col = 0; 		                     //resetez indicele de coloana
				buff_col = 1;		                  //resetez indicele de coloana al bufferului local
				
				world_we = 1'b0;
				update_done = 1'b0;
				state = `read_cell;
			end
			else if(col == 63)                      //am terminat de citit linia si acum trebuie sa calculez valorile pentru 
															  	 //a le scrie in world pe linia anterioara celei pe care tocmai am terminat-o de citit
			begin
				buff_col = 1; 								 //cand calculez regula vecinilor col pleaca de la valoarea 1!! corespunzatoare 
				buff_row = 1;								 //valorii 0 din world
				
				NVCES[4] = buffer[0][buff_col];		   //N		
				NVCES[3] = buffer[1][buff_col - 1];  	//V 			
				NVCES[2] = buffer[1][buff_col];        //C		/* 	0 - | N | - 		*/
				NVCES[1] = buffer[1][buff_col + 1];    //E 		/* 	1 V | C | E  		*/
				NVCES[0] = buffer[2][buff_col];	   	//S	   /* 	2 - | S | -  		*/	  
			 
				world_out = rule[NVCES];  					//selectam din regula pozitia corespunzatoare valorii noii celule	 
				row = row - 1;
				col = 0;
				world_we = 1'b1;
				update_done = 1'b0;
				state = `write_cell;
			end
		end
		
		`write_cell: 
		begin													//indicii de coloana sunt decalati cu o unitate pentru 
			buff_col = buff_col + 1;					//ca bufferul e bordat la stanga cu o coloana de 0
			
			NVCES[4] = buffer[0][buff_col];		   //N		
			NVCES[3] = buffer[1][buff_col - 1];  	//V 			
			NVCES[2] = buffer[1][buff_col];        //C		
			NVCES[1] = buffer[1][buff_col + 1];    //E 		
			NVCES[0] = buffer[2][buff_col];	   	//S	 
			
			world_out = rule[NVCES];  					//selectam din regula pozitia corespunzatoare valorii noii celule
			
			if(col < 63) 									//ramanem in aceasta stare pana cand se termina de scris lina in lume
			begin
				col = col + 1; 							// parcurgem pe coloana, caci facem scriere doar pe o linie
				world_we = 1'b1;    
				update_done = 1'b0;
				state = `write_cell;		
			end
			else if(col == 63 && row == 63)
			begin
				world_we = 1'b0;
				update_done = 1'b1;						//s-a terminat de procesat o generatie si se trece la urmatoarea
				state = `upt_done;
			end
			else if(col == 63) 							//trecem iar in starea de citire
			begin
				if(row < 62)								//in cazul in care nu am ajuns la procesarea ultimei linii
				begin
					col = 0;
					row = row + 2; 						//ne-am intors o linie inapoi ca sa scriem, acum ne ducem o linie peste pt citire
					for( k = 1; k < 65; k = k + 1)
					begin
						buffer[0][k] = buffer[1][k];  //shiftez liniile in sus ca sa pot citi urmatoarea linie pe buffer[2][]
						buffer[1][k] = buffer[2][k];
					end
					buff_row = 2;
					buff_col = 1;
					world_we = 1'b0;
					update_done = 1'b0;
					state = `read_cell;
				end
				else if(row == 62)						//penultima linie a fost procesata si scrisa anterior asa ca acum 
				begin											//o vom scrie pe ultima
					row = 63;
					col = 0;
					
					for( k = 1; k < 65; k = k + 1)
					begin
						buffer[0][k] = buffer[1][k];  //shiftez liniile in sus ca sa pot citi urmatoarea linie pe buffer[2][]
						buffer[1][k] = buffer[2][k];
					end
					for(k = 1; k < 65; k = k + 1)
						buffer[2][k] = 1'b0;				//bordam matricea, adica punem pe ultima linie a bufferului 0-uri
					
					buff_col = 1;
					buff_row = 1;
					
					NVCES[4] = buffer[0][buff_col];		 //N		
					NVCES[3] = buffer[1][buff_col - 1];  //V 			
					NVCES[2] = buffer[1][buff_col];      //C		
					NVCES[1] = buffer[1][buff_col + 1];  //E 		
					NVCES[0] = buffer[2][buff_col];		 //S	  
				
					world_out = rule[NVCES];  //selectam din regula pozitia corespunzatoare valorii noii celule	 
				
					world_we = 1'b1;    
					update_done = 1'b0;
					state = `write_cell;
					
				end
			end
			
		end
		
		`upt_done: 									//starea de terminare a unei generatii
		begin											//se reseteaza toti contorii	
			row = 0;
			col = 0;
			buff_col = 1;
			buff_row = 1;
			world_we = 1'b0;
			update_done = 1'b0;
			state = `read_cell;
		end
		
	 endcase
	end


endmodule