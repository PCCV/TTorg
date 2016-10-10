///////////////////////////////////////////////////////////////////
//  This file is part of TTorg.
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
//
// Copyright 2014-2016 C�me PASQUALIN, Fran�ois GANNIER
//////////////////////////////////////////////////////////////////

// package fg.menu;
// package ij.plugin;
import ij.*;
import ij.process.*;
import ij.gui.*;		// genericDialog
import ij.plugin.*;
import ij.Prefs;		//Prefs.get
import ij.util.*;
 // import ij.text.TextWindow;
// import ij.io.Opener;

import java.awt.*;
import java.io.*;
import java.util.*;

public class TT_org implements PlugIn {
	String sVer="TTorg ver. 1.2";
	String sCop="Copyright \u00A9 2014-2016 F.GANNIER - C.PASQUALIN";

	public void run(String arg) {
        if (arg.equals("options")) {
            showDialog();
            return;
        }
        if (arg.equals("")) {
        	return;
        }
		Macro_Runner.runMacroFromJar("Striation Analysis.ijm", arg);
	}

    void showDialog() { 
		boolean Verbose = (boolean) Prefs.get("TTorg.verbose",false); 
		boolean SMZm = (boolean) Prefs.get("TTorg.SMZm",true);
		boolean Dup = (boolean) Prefs.get("TTorg.Dup",false);
		String directory = Prefs.get("TTorg.directory",""); 
	
        GenericDialog gd = new GenericDialog(sVer);
//        gd.setInsets(0, 20, 0);
        gd.addMessage("Working Directory : "+directory+"    ");
		gd.addCheckbox("Verbose Mode", Verbose);
		gd.addCheckbox("Summarize Window", SMZm);
		gd.addCheckbox("Remove duplicate peaks", Dup);
		gd.addMessage(sCop);
		
		gd.addHelp("http://pccv.univ-tours.fr/ImageJ/TTorg/help.html");
		
        gd.showDialog();
        if (gd.wasCanceled())
			return;
		Verbose = gd.getNextBoolean();
		SMZm = gd.getNextBoolean(); 
		Dup = gd.getNextBoolean(); 
		Prefs.set("TTorg.verbose",Verbose); 
		Prefs.set("TTorg.SMZm",SMZm);
		Prefs.set("TTorg.Dup",Dup);
    }	
}

