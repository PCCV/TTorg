//////////////////////////////////////////////////////////////////
// TTorg - Analysis of Striations	 V1.2
// Author: Côme PASQUALIN, François GANNIER
//
// Signalisation et Transport Ionique (STIM)
// CNRS ERL 7368, Groupe PCCV - Université de Tours
//
// Report bugs to come.pasqualin@gmail.com
//
//  This file is part of TTorg.
//  Copyright 2014-2016 Côme PASQUALIN, François GANNIER	
//
//  TTorg is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  TTorg is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with TTorg.  If not, see <http://www.gnu.org/licenses/>.
//////////////////////////////////////////////////////////////////
var cmds = newArray("Analysis on entire image...", "Analysis on crop...", "Analyze All Slices ...", "Batch mode...","-","Create Test Image...","Set Display Color Mode..." , "Analyze background noise level","-", "TT Options...", "Select a working directory...", "-", "About");/**/

var menu = newMenu("Striation Analysis Menu Tool", cmds);

macro "Striation Analysis Menu Tool - C920T1b12TT9b12T" { // "TT"
	label = getArgument();
	if (label=="Analysis on entire image...")
		run(label);
    else if (label=="Analysis on Crop...")
		run(label);
    else if (label=="Analyze All Slices ...")
		run(label);
	else if (label=="Select a working directory...")
		ChangeWD();
	else if (label=="TT Options...")
		run(label);
	else if (label=="Set Display Color Mode...")
		Stack.setDisplayMode("color");	
	else if (label=="Create Test Image...")
		run(label);
	else if (label=="Analyze background noise level") {
		NoiseLevel();
	}
	else if (label=="Batch mode...") {
		run(label);
	}	else if (label=="About")
		About();
}	

function ChangeWD() {
	directory = getDirectory("Select a Working Directory");
	call("ij.Prefs.set", "TTorg.directory",directory);
}

function NoiseLevel(){
	if (nImages==0) {  exit("No images are opened"); }
	setTool("rectangle");
	waitForUser("Select rectangle of background \nand click ok");
	run("Set Measurements...", "  mean standard min add redirect=None decimal=2");
	run("Measure");
	selectWindow("Results");
	setLocation(1, 1);
	IJ.renameResults("Background_noise_level");
}

function About(){
	showMessage("About","TTorg v1.2 \nUniversity of Tours\nCopyright 2014-2016 F.GANNIER - C.PASQUALIN\n \nReport bugs to come.pasqualin@gmail.com");
}