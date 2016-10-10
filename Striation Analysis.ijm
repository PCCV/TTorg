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
//  Copyright 2014 Côme PASQUALIN, François GANNIER	
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


	crop = getArgument();
	if (crop =="") exit();

	var Verbose=false;
	if (call("ij.Prefs.get", "TTorg.verbose","false")=="true") Verbose = true;
	var SMZm=false;
	if (call("ij.Prefs.get", "TTorg.SMZm","true")=="true") SMZm=true;
	var Dup=false;
	if (call("ij.Prefs.get", "TTorg.Dup","false")=="true") Dup=true;
	var Debug = false;
	if (call("ij.Prefs.get", "TTorg.debug","false")==true) Debug=true;
	var TPBLC = true;
	if(call("ij.Prefs.get", "TTorg.tpblc","true")==false) TPBLC = false;
	
	var largeur; var hauteur; var unit; var nom; var nom_ori; var fftwin;	var pixelW; var pixelH;var Nbits; var channels; var sauvparamini; var detectbsd; var clausall; var sliceN; var noise;
	var ScH; var ScW; var periomin; var periomax; var seuilsd; var SDbd; var MedianFilt; var LoAI;

	crop = parseInt(crop);
	ScH = screenHeight;
	ScW = screenWidth;
	if (crop==2)  {
		//SMZ obligatoire
		SMZm=1; 
		Common();
		Batch_mode();
	} else {
		Common();
		AnalysisOfStriations(crop);
	}
	exit();
	
function Common() {
	if (TPBLC) Debug=0;
	if (Debug) Verbose=1;
	if (Debug || Verbose) Create_VerboseF();
	if (Debug || Verbose) VerboseF ("===== New analyse =====");
	if (SMZm) Create_Smz();
	noise = 27; periomin = 1.5; periomax = 2; seuilsd = 3.8; SDbd=false; MedianFilt=true; LoAI=true; sauvparamini=true;  sliceN = 1; detectbsd=0; clausall=0;
}

function AnalysisOfStriations(crop) {
	init_Common_values();
	if (pixelH != pixelW) {	exit("Image must have squared pixel:");}
	if (nImages==0) {  exit("No open image"); }
	// working directory
	directory = call("ij.Prefs.get", "TTorg.directory",""); 
	if (directory=="") {
		directory = getDirectory("Select a Working Directory");
		call("ij.Prefs.set", "TTorg.directory",directory); 
	}
	if (Debug) VerboseF ("crop = "+crop);
	if  (crop!=1) {
		if (Verbose) VerboseF ("on entire image");
		multia = 0; sauvlist = 0; sauvparam = 1;
		if  (nImages>1) {
			multia = getBoolean("Perform analyse on all opened images ?");
		}
		//On verifie qu'un fichier de parametres existe dans working directory, si oui, on propose de le charger
		fexist = File.exists(directory+"parameter.txt"); 
		loadf = 0;
		if (fexist) loadf = getBoolean("A parameter file already exits, load these parameters ?");
		if (fexist) 	{
//		if (fexist && loadf) 	{
			if (Verbose) VerboseF ("Loading parameters");
			noise = get_param(directory, "SSPD");
			periomin = get_param(directory, "Minimum spacing");
			periomax = get_param(directory, "Maximum spacing");
			seuilsd = get_param_d(directory, "SD seuil", seuilsd);
			detectbsd = get_param_d(directory, "Circular integration", detectbsd);
			sauvlist = get_param_d(directory, "Save list of analysed images", sauvlist);
			if (multia) sauvparam = get_param_d(directory, "Save parameters",sauvparam); else sauvlist=false;
			MedianFilt = get_param_d(directory, "Median filter",MedianFilt);
			clausall = get_param_d(directory, "Close all",clausall);
		} 
		if (!loadf) {
			//boîte de dialogue pour acquisition des paramètres operateur (si pas de chargement du fichier de param)
			Dialog.create("Analysis parameters");
			Dialog.addMessage("Pixel size : "+d2s(pixelH,7)+" "+unit);
			Dialog.addNumber("SSPD :", noise); //seuil de detection du pic dans la FFT
			Dialog.addNumber("Minimum spacing :", periomin, 3, 6, unit);
			Dialog.addNumber("Maximum spacing :", periomax, 3, 6, unit);
			if (!TPBLC) Dialog.addNumber("SD threshold (for CIA) (xSD):", seuilsd);
			if (!TPBLC) Dialog.addCheckbox("Circular integration analysis (CIA)", SDbd);
			if (!TPBLC) Dialog.addCheckbox("Median Filter", MedianFilt);
			if (multia) Dialog.addCheckbox("Save list of analysed images", LoAI);
			Dialog.addCheckbox("Save these parameters", sauvparamini);
			if (!multia) Dialog.addCheckbox("Close all after analysis", clausall); //fermeture obligatoire pour la poursuite de l'analyse
			Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");
			Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/TTorg/help.html");
			Dialog.show();
			noise = Dialog.getNumber();
			periomin = Dialog.getNumber();
			periomax = Dialog.getNumber();
			if (!TPBLC) seuilsd = Dialog.getNumber();
			if (!TPBLC) detectbsd = Dialog.getCheckbox();
			if (!TPBLC) MedianFilt = Dialog.getCheckbox();
			if (multia) sauvlist = Dialog.getCheckbox(); else sauvlist=false;
			sauvparam = Dialog.getCheckbox();
			if (!multia) clausall = Dialog.getCheckbox();	
		}
		if (Verbose) {
			VerboseF ("===== parameters =====");
			VerboseF ("pixel size : "+d2s(pixelH,11));
			VerboseF ("SSPD : "+noise);/**/
			VerboseF ("striation interval : ["+periomin+" ; "+periomax+"]");
			if (!TPBLC) VerboseF ("SD threshold : "+seuilsd);
			if (!TPBLC) VerboseF ("CIA : "+detectbsd);
			VerboseF ("save list : "+sauvlist);
			if (!TPBLC) VerboseF ("median filter : "+MedianFilt); /**/
			VerboseF ("save params : "+sauvparam);
		}		//fermeture obligatoire des imgages pour poursuivre l'analyse
		if (multia) clausall = true;
		Create_LogF();
		// Sauvegarde de la liste des images
		if (sauvlist) {
			if (Verbose) VerboseF ("Saving images list");
			setBatchMode(true);
			LogF("List of analysed images:\n");
			for (i=1; i<=nImages; i++) {
				selectImage(i);
				LogF(""+getTitle);
			}
			Save_CloseW("TT_Log", "Text", ""+directory+"analysed_list.txt");
			setBatchMode(false);
		}
		if (sauvparam==true) Save_Param();
// ANALYSE
		iniTime = getTime();
		if (multia) ni = nImages; else ni=1;
		while (ni > 0) {
			//sélection des images une par une
			init_Common_values();
			if (Verbose) { 
				VerboseF ("=== Analyse Image "+ni+" ===");
				VerboseF("File : " + nom_ori); 
				VerboseF("Copy : " + nom);
			}
			Nslice = 1;
			var numChannel=0;
			if (multia) selectImage(ni);
			if (crop==3) {
				if (channels>1) {
					numChannel = getNumber("Which Channel (0 for all) ?",1);
					if (numChannel>channels) numChannel=1;					
					if (Verbose) VerboseF ("" + nSlices  + " slices on " + channels + " channels" );
				}
				if (numChannel==0) {
					channels = 1;
					Nslice = nSlices;
				}
				else Nslice = nSlices / channels;
			} /**/
			while (Nslice > 0) {
				selectWindow(nom_ori);
				if (crop==3) 	{
//					slice = Nslice - (Channels - numChannel);
					if (Verbose) VerboseF ("=== Analyse Slice "+ Nslice +" (ch "+numChannel+")"+" ===");
					if (channels>1)
						setSlice(Nslice*channels-(channels - numChannel));
					else setSlice(Nslice);					
//					setZCoordinate(Nslice/channels-1);
				}

				setName();
				//détermination de la plus grande dimension de la fenetre (en pix)
				fftwin = Fenetre_fft(largeur,hauteur);
				selectWindow(nom_ori);
				getStatistics(area_1, mean_1, min_1, max_1, std_1, histogram_1);
				if (max_1 == 0) {
					if (Verbose == 1) VerboseF("No image");
				} else /**/{
					run("Select All");  run("Copy");
					if (Debug) VerboseF ("Creating new image : " + nom);
					newImage(nom, Nbits+"-bit black", fftwin, fftwin, 1);
					run("Paste");
					
					selectWindow(nom); 
					if (MedianFilt) {
						if (Verbose) VerboseF ("Applying Median filter");
						run("Median...", "radius=2 slice");
					}

					if (Verbose) VerboseF ("Enhancing contrast");
					Normalize(Nbits,fftwin,fftwin);

			//création de la fenêtre de Hanning
					if (Verbose) VerboseF ("Determining Hanning window");
					Hanning_name = Hanning_window(fftwin);
					
					//multiplication de l'image par Hanning et renommage
					imageCalculator("Multiply create 32-bit", nom, Hanning_name);
					if (Nbits < 32) run(Nbits+"-bit");
					CloseW(Hanning_name);
					CloseW(nom);
					
					selectWindow("Result of "+nom+"");
					if (Debug) VerboseF ("Renaming 'Result of "+nom + "' to " + nom);
					rename(nom);

					//on redefinit la taille correcte du pixelH
//					selectWindow(nom); id = getImageID();	
					setLocation(1, 1, 400, 400);
					run("Properties...", "unit=micron pixel_width="+pixelH+" pixel_height="+pixelH+" voxel_depth=1");
								
					//réalisation de la FFT sur l'image
					if (Verbose) VerboseF ("Processing FFT");
		//			selectWindow(nom);
					run("FFT"); 
					setLocation(1, 401, 400, 400);

					//detection basée sur SD (nouvelle methode) = Integration circulaire CIA
					if (detectbsd==true) {
	// nouvelle methode d'analyse avec la std apres duplication de la FFT
						run("Duplicate...", "title=[FFT2"+nom+"]");
						selectWindow("FFT2"+nom+"");
						setLocation(401, 1, 400, 400);
						if (Verbose) VerboseF ("Substracting background");
						run("Subtract Background...", "rolling=30");
						getStatistics(areafft, meanfft, minfft, maxfft, stdfft);

						run("Subtract...", "value="+seuilsd*stdfft+" slice");

						periodmin = periomin;
						periodmax = periomax;
						if (Verbose) VerboseF ("Circular integration : ["+periodmin+" ; "+periodmax+"] "+unit);
						Integration_circFFT(fftwin,pixelH,periodmin,periodmax,unit,nom);
						
						//sauvegarde du log de la nouvelle analyse
						SaveW(""+nom+"_FFT_circular_integ", "Text", ""+directory+""+nom+"_FFT_circular_integ.txt");
						
						// fermeture intelligente
						CloseW("FFT2"+nom+"");
						//fermeture de la fenetre si demandé par operateur
						if (multia && clausall) {
							CloseW("FFT2"+nom+"");
							CloseW("Plot of "+nom);
						}
						selectWindow("FFT of "+nom+"");
					}
					// ===================  analyse classique ==================
					run("Subtract Background...", "rolling=30");
					if (Verbose) VerboseF ("Determining window of analysis");
					//Création de la fenêtre d'analyse	
					//Calcul de l'emplacement dans la FFT de la fréquence voulue
					vartemp = fftwin * pixelH;
					//grand cercle (periode minimum) arrondi au pix superieur : variable grdraypix
					grdraypix = floor (vartemp/periomin) + 1;
					//petit cerlce pour espacement max (periode maximum) arrondi au pix inferieur : variable pttraypix
					pttraypix = floor (vartemp/periomax);
					//création de la zone de recherche
					tor(fftwin/2-grdraypix, fftwin/2-grdraypix, grdraypix*2,fftwin/2-pttraypix, fftwin/2-pttraypix, pttraypix*2);

					//selection des maxima-locaux pour visualisation
					vartemp = Create_results(1);
					freqcorr=getInfo("window.contents");
					run("Close"); // ??
					
					nomfen = "";// permet de creer la variable, meme si on ne s'en sert pas! 
//					if (vartemp >= periomin) 
					{ //permet de ne rien ecrire s'il n'y a pas de pic detecté
						run("Text Window...", "name=temp_log width=72 height=10 monospaced");

						nomfen = ""+substring(nom, 0, lengthOf(nom)-4);
						SaveW("temp_log", "Text", ""+directory+""+nomfen+".txt");
						nomfen2 = "["+nomfen+".txt]";
						print(nomfen2,freqcorr);
					}
	//sauvegarde du fichier (le fait qu'il soit ici permet de ne rien sauver s'il n'y a rien  d'ecrit
					SaveW(nomfen+".txt", "Text", ""+directory+""+nomfen+".txt");

					if (clausall || multia) {
						CloseW(nom);
						CloseW("FFT of "+nom+"");
						CloseW(nomfen+".txt");
	// en double pour fenetre qui ne se ferme pas !!!
						CloseW(nom);
						CloseW("FFT of "+nom+"");
					}					
				}
				Nslice--;
			} // fin NSlice
			if (Verbose) VerboseF ("Analysis done");
			if (multia) { 
				CloseW(nom_ori);
				ni = nImages; 
			} else ni=0;
		}
		finTime = getTime();
		beep();
	//	if (multia) waitForUser( "The end","Analyse complete !\n("+calcTime(iniTime,finTime)+")"); 
		if (Verbose) VerboseF ("Analysis completed !\n("+calcTime(iniTime,finTime)+")");
	} else { //Crop == 1
		pheight=10; pwidth=40; tangledeg=15;
		if (Verbose) VerboseF ("on crop images");
		init_Common_values();
		{
			Dialog.create("Analysis parameters");
			Dialog.addMessage("Pixel size : "+d2s(pixelH,7)+" "+unit);
			Dialog.addNumber("SSPD : ", noise); //seuil de detection du pic dans la FFT
			Dialog.addNumber("Crop width :", d2s(255*pixelH,1), 2, 4, unit);
			Dialog.addMessage("Recommanded values : " + d2s(255*pixelH,1)  + " (256px)\n or " + d2s(511*pixelH,1) + " (512px) or " + d2s(1023*pixelH,1)+" (1024px)");
			Dialog.addMessage("");
			Dialog.addNumber("Crop height :", pheight, 2, 4, unit);
			Dialog.addNumber("Minimum spacing :", periomin, 3, 6, unit);
			Dialog.addNumber("Maximum spacing :", periomax, 3, 6, unit);		
			Dialog.addNumber("angular tolerance ("+fromCharCode(0x00B0)+"):", tangledeg); 
			if (!TPBLC) Dialog.addNumber("SD threshold (for CIA)(xSD):", seuilsd);
			if (!TPBLC) Dialog.addCheckbox("Circular integration analysis (CIA)", SDbd);
			if (!TPBLC) Dialog.addCheckbox("Median Filter", MedianFilt);
			Dialog.addCheckbox("save portions grey level profiles", false);
			Dialog.addCheckbox("Close all after analysis", clausall);
			Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");
			Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/TTorg/help.html");
			Dialog.show();
			noise = Dialog.getNumber();
			pwidth = Dialog.getNumber();
			pheight = Dialog.getNumber();
			periomin = Dialog.getNumber();
			periomax = Dialog.getNumber();
			tangledeg = Dialog.getNumber();
			if (!TPBLC) seuilsd = Dialog.getNumber();
			if (!TPBLC) detectbsd = Dialog.getCheckbox();
			if (!TPBLC) MedianFilt = Dialog.getCheckbox();
			savportion = Dialog.getCheckbox();
			clausall = Dialog.getCheckbox();
		}
//conversion de pheight en pixels -> pheightpix et calcul de la largeur des portions
		pheightpix = pheight / pixelH;
		lportion = pwidth / pixelH;

		// calcul des dimensions de la fenêtre FFT résultante (variable fftwin)
		fftwin = Fenetre_fft(lportion,pheightpix);
		setTool("line");
		waitForUser( "Selection","Use the straight or segmented line tool \nto draw a line along the cell \n Then click 'OK'"); 
		
		iniTime = getTime();
//crop de la partie d'intérêt !!! à l'apparition de fréquences parasites lors de la FFT
		run("Straighten...", "line="+pheightpix+"");
		rename("crop");
		selectWindow("crop");
		setLocation(1,1);
		
		lcrop = getWidth();		
//ajustement du contraste par normalisation de l'histogramme pour limiter les fluctuations de marquage inter-échantillon
		if (Verbose) VerboseF ("Enhancing contrast");
		Normalize(Nbits, lcrop, pheightpix);
		if (MedianFilt) {
			if (Verbose) VerboseF ("Applying Median filter");
			run("Median...", "radius=2 slice");
		}
//---------------------------------------------------------------------------------------
//Fractionnement de la sélection en portion de xxx µm de long
		if (lcrop<lportion){
		// arrêt de l'execution si la longueur de la cellule est inferieur à la longueur du crop
			CloseW("crop");
			exit("Error: cell length < crop size");
		}
		// calcul du nombre de portions faisables (integer):
		nportions = floor(lcrop / lportion);
		run("Text Window...", "name=Crop_Log width=72 height=10 monospaced");

		// Découpage du crop en portions
		for(i=1; i<(nportions+1); i++) {
			if (Verbose) VerboseF ("=== Analyse Section "+(i)+"/"+nportions+" ===");
			showProgress(i/nportions);
			makeRectangle(0+((i-1)*lportion), 0, lportion, pheightpix);
			if (Debug) VerboseF ("duplicating... "+ i);
			run("Duplicate...", "title="+i);
		 
		 //Récupération des valeurs de la somme des pixels de chaque colonne de la portion
			if (savportion==true) {
				run("Select All");
				run("Plot Profile");
				Plot.getValues(xpoints, ypoints);
				fenetre= "["+nom+" Profile de portion "+i+"]";
				run("Text Window...", "name="+fenetre+" width=72 height=8  monospaced");
				for (m=0; m<xpoints.length; m++) {
					print(fenetre, ""+xpoints[m]+" "+ypoints[m]+"\n");
				}
				Save_CloseW(nom+" Profile de portion "+i, "Text", ""+directory+""+nom+"_PP_"+i+".txt");
			}
			//réalisation de la FFT sur la portion
			if (Verbose) VerboseF ("Pre-processing FFT");
			selectWindow(i); run("Select All"); run("Copy"); CloseW(""+i); 
			if (Debug) VerboseF ("Creating new image : "+i);
			newImage(i, Nbits+"-bit black", fftwin, fftwin, 1);
			run("Select All"); 	run("Paste");

			if (Verbose) VerboseF ("Determining Hanning window");
			Hanning_name = Hanning_window(fftwin);
			imageCalculator("Multiply create 32-bit", ""+i+"", Hanning_name);
			if (Nbits < 32) run(Nbits+"-bit");
			CloseW(Hanning_name); 
			CloseW(""+i);
			if (Debug) VerboseF ("Renaming 'Result of "+i+ "' to " + i);
			selectWindow("Result of "+i+"");	rename(i);
			//on redefinit la taille correcte du pix
			selectWindow(i);
			run("Properties...", "unit=micron pixel_width="+pixelH+" pixel_height="+pixelH+" voxel_depth=1");

			if (Verbose) VerboseF ("Processing FFT");
			run("FFT");			
			//analyse basée sur SD si demandée
			if (detectbsd==true) {
				//nouvelle methode d'analyse avec la std apres duplication de la FFT
				run("Duplicate...", "title=[FFT2"+i+"]");
				selectWindow("FFT2"+i+"");
				run("Subtract Background...", "rolling=30");
				getStatistics(areafft, meanfft, minfft, maxfft, stdfft);
				run("Subtract...", "value="+seuilsd*stdfft+" slice");

				periodmin = periomin;
				periodmax = periomax;
				Integration_circFFTangle(fftwin,pixelH,periodmin,periodmax,unit,nom);

				SaveW(""+nom+"_"+i+"_FFT_circular_integ","Text", ""+directory+""+nom+"_"+i+"_FFT_circular_integ");
			
				if (clausall==true) run("Close");
				selectWindow("FFT of "+i+"");
				roiManager("reset");
			}
		// ANALYSE CLASSIQUE
			if (Verbose) VerboseF ("Substracting background");
			run("Subtract Background...", "rolling=30");
		//Création de la fenêtre d'analyse CLASSIQUE
			if (Verbose) VerboseF ("Determining window of analysis");
		//Calcul de l'emplacement dans la FFT de la fréquence voulue
			vartemp = fftwin * pixelH;
		//grand cercle (periode minimum) arrondi au pix superieur : variable grdraypix
			grdraypix = floor (vartemp/periomin) + 1;
		//petit cerlce pour espacement max (periode maximum) arrondi au pix inferieur : variable pttraypix
			pttraypix = floor (vartemp/periomax);

		// selection de l'anneau
			tor(fftwin/2-grdraypix, fftwin/2-grdraypix, grdraypix*2,fftwin/2-pttraypix, fftwin/2-pttraypix, pttraypix*2);
			Create_roi(fftwin, tangledeg);
			selectWindow("ROI Manager");
			setLocation(1, ScH-60);
			run("Find Maxima...", "noise="+noise+" output=List");
			nbmaxima = nResults;
	
			vartemp = Create_results(1);
			freqcorr=getInfo("window.contents");
			run("Close");

			print("[Crop_Log]"," \n");
			print("[Crop_Log]","crop "+i+"/"+nportions+"\n");
			if (nbmaxima > 0) print("[Crop_Log]",freqcorr+"\n");
			else print("[Crop_Log]","No peak have been detected in FFT\n");
			print("[Crop_Log]","------------------------------------------------------------------\n");

			//on vide le ROI manager pour ne pas interferer avec les anciennes selections
			roiManager("reset");
			selectWindow("crop");
			if (Verbose) VerboseF ("Done");
		}
//		CloseW("crop");
		SaveW("Crop_Log","Text", ""+directory+""+substring(nom, 0, lengthOf(nom)-4)+"_log.txt");
		CloseW("ROI Manager");
		for(i=1; i<(nportions+1); i++) {
			CloseW(""+i);
		}
		if (clausall==true) {
			CloseW("crop");
//			run("Close All");
			CloseW("Crop_Log");
			for(i=1; i<(nportions+1); i++) {
				CloseW("FFT of "+i+"");
			}
		}	

		finTime = getTime();
		if (Verbose) VerboseF ("Time to complete : "+calcTime(iniTime,finTime));
		if (Verbose) VerboseF ("=== All done ===");
	}
}

function roundn(num, n) {
	return parseFloat(d2s(num,n))
}

function setName() {
	nom = substring(nom_ori, 0, lastIndexOf(nom_ori, "."))+"_"+getSliceNumber()+ 		substring(nom_ori, lastIndexOf(nom_ori, "."),lengthOf(nom_ori));
}

function init_Common_values() {
	getDimensions(largeur, hauteur, channels, slices, frames);
	getPixelSize(unit, pixelW, pixelH);
	pixelW = roundn(pixelW, 7);
	pixelH = roundn(pixelH, 7);
	nom_ori = getTitle();
	if (crop==2) nom = nom_ori;
	else setName();
	Nbits = bitDepth();
}

function Create_results(correc){
	updateResults();
	run("Find Maxima...", "noise="+noise+" output=[Point Selection]");
	//selection des maxima pour analyse
	run("Set Measurements...", "  min add redirect=None decimal=2");
	run("Properties...", "pixel_width=1 pixel_height=1");
	run("Measure");
	selectWindow("Results");
	setLocation(1,800);
	title_Result = "FFT_peaks";
	title_Result2 = "["+title_Result+"]";
	run("New... ", "name="+title_Result2+" type=Table"); 
	print(title_Result2,"\\Headings:Power (AU)\tPeriod ("+unit+")\taccuracy ("+unit+")\tAngle ("+fromCharCode(0x00B0)+")"); 
	if (Dup) pas = 2; else pas=1;
	for(j=0; j<nResults; j+=pas) {
		x = getResult("Max",j);
		test = getResult("R", j);
		if (correc==0) {
			y = test; r = 1;
		} else {
			e = correc_bug(getResult("X", j), getResult("Y", j), fftwin);
			y = pixelH*fftwin/e; 
			r = pixelH*fftwin/(e*(e-1))/2;
			if (y != test) 
				if (Debug) {
					VerboseF ("R (ImageJ):"+ test+"    correction FG :"+y);
				} /**/
		}
		if (isNaN(y)) x = NaN;
		if (Debug) VerboseF ("y:"+y+"    x:"+x);
		print(title_Result2,x+"\t"+d2s(y,3)+"\t"+fromCharCode(0x00B1)+""+d2s(r,3)+"\t"+d2s(getResult("Theta", j),1)); 
		if (SMZm) {
			print("[SMZ]",nom+"\t"+x+"\t"+d2s(y,3)+"\t"+fromCharCode(0x00B1)+""+d2s(r,3)+"\t"+d2s(getResult("Theta", j),1));
		}
	}
	CloseW("Results");
	selectWindow(title_Result);
	run("Properties...", "pixel_width="+pixelH+" pixel_height="+pixelH);	
	return test;
}

function Fenetre_fft(largeur,hauteur){
//fonction de calcul des dimensions de la fenêtre de la FFT correspondante
//parametre : taillefen = plus grande dimension (l ou L) de la fenetre de l'image
//renvoi: fftwin (correspondant à la plus petite taille de fenêtre en pixel pouvant inclure l'image
	if (largeur>=hauteur)
		taillefen =  largeur;
	else  taillefen =  hauteur;		
	iii = 0;
	while(taillefen>1) { taillefen /= 2; iii++;}
	return pow(2,iii);
}

function tor(x1,y1,d1, x2, y2, d2){
//fonction de sélection cirulaire (anneau de pixels)
//1 correspond au cercle le plus grand, et 2 au cercle le plus petit
//x et y correspond aux coordonnées top/left et d au diamètre
//à la fin, vidange du ROI manager et fermeture
	imageid = getImageID();
	
	roiManager("reset");
	makeOval(x1, y1, d1, d1);
	roiManager("Add");
	makeOval(x2, y2, d2, d2);
	roiManager("Add");
	roiManager("XOR");
	roiManager("reset");
	CloseW("ROI Manager");

	selectImage(imageid);
}

function Posdansfft(fftwin,pix,period){
// fonction qui renvoie la distance en pixel de la period (en micron "unit") par rapport au centre du spectre DISTANCE ARRONDIE AU PIXEL INFERIEUR !!!
// fftwin = dimension d'un coté du spectre en pixel (ex: 512)
// pix = taille du pixel (en "unit" (microns))
// la period doit etre spécifiée en "unit" donc microns
// renvoi: location
	location = floor ( fftwin * pix / period );
	return location;
}

function Hanning_window(fftsize){
	//crée la fenetre de hanning et la garde comme image active
	Hanning_name = "hanning"+fftsize+".tif";
	dir = getDirectory("temp");
	if (File.exists(dir+Hanning_name)) {
		open(dir+Hanning_name);		
	} else {
		run("Create Hanning W...","fftsize="+fftsize);
		save(dir+Hanning_name);
	} 
	return getTitle(); // correction for FIJI;
}

function Integration_circFFT(fftwin,pix,periodmin,periodmax,unit,nom){
// calcul pour chaque anneau d'1 pix d'epaisseur, la somme des pixels de l'anneau, la moyenne, et le nombre (implémentation d'un array)
// pour des anneaux de la periodmax à la periodmin
// on commence par les petits anneaux (donc periodmax) et par le petit cercle
// periodmin et max en microns
// fftwin en pix
// pix = taille du pixel en "unit"
// unit

// calcul de la position (en pixel de periodmin et periodmax par rapport au centre)
periodminpix = Posdansfft(fftwin,pix,periodmin);
periodmaxpix = Posdansfft(fftwin,pix,periodmax);
periodmaxpixini = periodmaxpix;
periodminpix = periodminpix + 1; // periodmin pix correspond au plus grand cercle. On arrondi au pixel supérieur pour ne pas perdre une valeur

// calcul des coordonnées du centre de la fftwin
xycentre = fftwin / 2; 

// nombre de pixels entre min et max
nbanneaux = periodminpix - periodmaxpix;

run("Set Measurements...", "area mean standard min integrated median add redirect=None decimal=2");

for(i=1; i<=nbanneaux; i++) { //eventuellement faire ca avec une boucle while pour ne pas compter les anneaux
	
	// création de l'anneau
	tor(xycentre-periodmaxpix+1,xycentre-periodmaxpix+1,2*periodmaxpix+1,xycentre-periodmaxpix,xycentre-periodmaxpix,2*periodmaxpix);
	
	// mesure
	run("Measure");
	
	// incrementation de periodmaxpix
	periodmaxpix = periodmaxpix + 1;
}

// réécriture de la fenetre results proprement, et avec les periodes correspondant à chaque pixel
	selectWindow("Results");
	setLocation(1, ScH/2);
	title_Result = ""+nom+"_FFT_circular_integ";
	title_Result2 = "["+title_Result+"]";
	run("New... ", "name="+title_Result2+" type=Table"); 
	// print(title_Result2,"\\Headings:Period ("+unit+")\tArea\tMean\tMax\tIntDen\tIntDen/Area"); 
	print(title_Result2,"\\Headings:Period ("+unit+")\tIntDen/Area (UA)"); 

	//création de deux array pour plotter
	periodA = newArray(nResults);
	IntDenAreaA = newArray(nResults);
	
	for(j=0; j<nResults; j++) {
		a = getResult("Area",j);
		b = getResult("Mean",j);
		c = getResult("Max",j);
		d = getResult("IntDen",j);
		e = fftwin * pix / periodmaxpixini; //periode
		f = d / a;
		// print(title_Result2,e+"\t"+a+"\t"+b+"\t"+c+"\t"+d+"\t"+f+""); 
		print(title_Result2,e+"\t"+f+""); 
		
		// incrementation de periodmaxpixini
		periodmaxpixini = periodmaxpixini + 1;
		
		//ici remplissage des array
		periodA[j] = e;
		IntDenAreaA[j] = f;
		
	}
	
	// creation du plot
	Array.getStatistics(IntDenAreaA, minIDAA, maxIDAA, meanIDAA, stdIDAA); //on recup le max pour donner l'echelle
	Array.getStatistics(periodA, minPA, maxPA, meanPA, stdPA); //on recup le min et le max pour donner l'echelle
	Plot.create("Plot of "+nom, "Period ("+unit+")", "IntDen/area (UA)"); //, periodA, IntDenAreaA);
	Plot.setLimits(minPA, maxPA, 0, maxIDAA+(stdIDAA/2));
	Plot.setLineWidth(2);
	Plot.setColor("red");
	Plot.add("line", periodA, IntDenAreaA);
	Plot.setLineWidth(1);
	Plot.setColor("lightGray");
	Plot.add("cross", periodA, IntDenAreaA);
	Plot.show();
	setLocation(401, 401);
	
	//on complète la fenetre result avec l'integrale totale du pic
	IntTOT = lengthOf(IntDenAreaA) * meanIDAA;
	print(title_Result2," \t ");
	print(title_Result2," \tVolume of peaks on FFT interval:");
	print(title_Result2," \t"+d2s(IntTOT,7));
	
	if (SMZm) {
		print("[SMZ]",nom+"\t\t\t\t\t"+d2s(IntTOT,7));
	}
	
	CloseW("Results");
	selectWindow(title_Result);

// on remet la fenetre results comme elle etait
// run("Set Measurements...", "  min add redirect=None decimal=2");
}

function Integration_circFFTangle(fftwin,pix,periodmin,periodmax,unit,nom){
// calcul pour chaque anneau d'1 pix d'epaisseur, la somme des pixels de l'anneau, la moyenne, et le nombre (implémentation d'un array)
// pour des anneaux de la periodmax à la periodmin
// on commence par les petits anneaux (donc periodmax) et par le petit cercle
// periodmin et max en microns
// fftwin en pix
// pix = taille du pixel en "unit"
// unit

// calcul de la position (en pixel de periodmin et periodmax par rapport au centre)
periodminpix = Posdansfft(fftwin,pix,periodmin);
periodmaxpix = Posdansfft(fftwin,pix,periodmax);
periodmaxpixini = periodmaxpix;
periodminpix = periodminpix + 1; // periodmin pix correspond au plus grand cercle. On arrondi au pixel supérieur pour ne pas perdre une valeur

// calcul des coordonnées du centre de la fftwin
xycentre = fftwin / 2; 

// nombre de pixels entre min et max
nbanneaux = periodminpix - periodmaxpix;

run("Set Measurements...", "area mean standard min integrated median add redirect=None decimal=2");

for(k=1; k<=nbanneaux; k++) { //eventuellement faire ca avec une boucle while pour ne pas compter les anneaux
	
	// création de l'anneau
	tor(xycentre-periodmaxpix+1,xycentre-periodmaxpix+1,2*periodmaxpix+1,xycentre-periodmaxpix,xycentre-periodmaxpix,2*periodmaxpix);
	Create_roi(fftwin, tangledeg);
	run("Measure");
	// incrementation de periodmaxpix
	periodmaxpix = periodmaxpix + 1;
}

// réécriture de la fenetre results proprement, et avec les periodes correspondant à chaque pixel
	selectWindow("Results");
	title_Result = ""+nom+"_"+i+"_FFT_circular_integ";
	title_Result2 = "["+title_Result+"]";
	run("New... ", "name="+title_Result2+" type=Table"); 
	// print(title_Result2,"\\Headings:Period ("+unit+")\tArea\tMean\tMax\tIntDen\tIntDen/Area (UA)"); 
	print(title_Result2,"\\Headings:Period ("+unit+")\tIntDen/Area (UA)"); 

	//création de deux array pour plotter
	periodA = newArray(nResults);
	IntDenAreaA = newArray(nResults);
	
	for(j=0; j<nResults; j++) {
		a = getResult("Area",j);
		b = getResult("Mean",j);
		c = getResult("Max",j);
		d = getResult("IntDen",j);
		e = fftwin * pix / periodmaxpixini; //periode
		f = d / a;
		// print(title_Result2,e+"\t"+a+"\t"+b+"\t"+c+"\t"+d+"\t"+f+""); 
		print(title_Result2,e+"\t"+f+""); 
		// e = Posdansfft(fftwin,pix,periodmaxpixini);
		// incrementation de periodmaxpixini
		periodmaxpixini = periodmaxpixini + 1;
		
		//ici remplissage des array
		periodA[j] = e;
		IntDenAreaA[j] = f;
	}
	
	// creation du plot
	Array.getStatistics(IntDenAreaA, minIDAA, maxIDAA, meanIDAA, stdIDAA); //on recup le max pour donner l'echelle
	Array.getStatistics(periodA, minPA, maxPA, meanPA, stdPA); //on recup le min et le max pour donner l'echelle
	Plot.create("Plot of "+nom+"_crop_"+i+"", "Period ("+unit+")", "IntDen/area (UA)", periodA, IntDenAreaA);
	Plot.setLimits(minPA, maxPA, 0, maxIDAA+(stdIDAA/2));
	Plot.setLineWidth(2);
	Plot.setColor("red");
	Plot.add("line", periodA, IntDenAreaA);
	Plot.setLineWidth(1);
	Plot.setColor("lightGray");
	Plot.add("cross", periodA, IntDenAreaA);
	Plot.show();
	
	//on complète la fenetre result avec l'integrale totale du pic
	IntTOT = lengthOf(IntDenAreaA) * meanIDAA;
	print(title_Result2," \t "); //petit espace pour clareté
	print(title_Result2," \tVolume of peak on FFT interval:"); //titre
	print(title_Result2," \t"+d2s(IntTOT,7));

/*	if (SMZm) Summurize_mode ("CIA totale (angle) = "+d2s(IntTOT,7));	*/
	
	CloseW("Results");
	selectWindow(title_Result);
}

function get_param(path, key) {
	file = File.openAsString(path+"parameter.txt");
//	lines=split(file,"\n")
	poskey = indexOf(file, key);
	if (poskey<0) return NaN;
	posval = indexOf(file, "=", poskey);
	if (posval<0) return NaN;
	posfin = indexOf(file, "\n", posval);
	if (posfin<0) return NaN;
	return parseFloat(substring(file,posval+1,posfin));
}

function get_param_d(path, key, dflt) {
	val = get_param(path, key);
	if (isNaN(val)) return dflt;
	else return val;
}

function correc_bug(X, Y, psize) { //(X,Y) coor en pixel
//  calculate the correct value for R 	//  return the distance from center 
	center = psize/2;
	diffX = center - X;
	diffY = center - Y;
	ecart = sqrt(diffX*diffX+diffY*diffY);
	if(Debug) {
		VerboseF("===== Correction =====");
		VerboseF("pix size ="+d2s(pixelH,11));
		VerboseF("taille image : " + psize + " x " + psize);
		VerboseF("position centre : " + center + " : " + center);
		VerboseF("ecart//centre = " + ecart);
	}
	return (ecart);
}

function calcTime(iniTime, finTime) {
	durationTime = finTime - iniTime;
	nbH = floor ( durationTime / 3600000);
	nbM = floor ( durationTime / 60000 ) - ( nbH * 3600000 );
	nbS = floor ( durationTime / 1000 ) - ( ( nbM * 60) + (nbH * 3600) );
	delayTime = ""+nbH+" h "+nbM+" min "+nbS+" s";
	return delayTime;
}

function Batch_mode() {
	run("Bio-Formats Macro Extensions");
	// ATTENTION, le repertoire ne doit contenir que des fichiers images
	// choix du répertoire contenant les images à traiter
	directory = getDirectory("Select a Working Directory");

	// recupération de la liste des image, sauvegarde de cette liste et remplissage d'un array contenant leurs nom
	TempList = getFileList(directory);
	nbImg = lengthOf(TempList);
	ImgList = newArray(nbImg);
	nbimg2 = 0;
	for (b=0; b<nbImg; b++){
		nom = TempList[b];
		Ext.isThisType(directory+nom, thisType);
//		print(directory+nom+" : "+thisType);
		if (thisType=="true") {
			ImgList[nbimg2++] = nom;
		}
	}
	ImgList = Array.trim(ImgList, nbimg2);
	nbImg = lengthOf(ImgList);
	// boite de dialogue pour choix des paramètres 
	// (avec proposition de sauvegarde et du fichier de paramètre)
	// ATTENTION, ne pas proposer de charger un fichier de parametre car le dossier ne doit contenir que des images
	clausall=1;
	{
		Dialog.create("Analysis parameters");
		// Dialog.addMessage("Pixel size : "+d2s(pix,7)+" "+unit);
		Dialog.addNumber("SSPD :", noise); //seuil de detection du pic dans la FFT
		Dialog.addNumber("Minimum spacing :", periomin, 3, 6, "µm");
		Dialog.addNumber("Maximum spacing :", periomax, 3, 6, "µm");
		if (!TPBLC) Dialog.addNumber("SD threshold (for CIA) (xSD):", seuilsd);
		Dialog.addNumber("Select analyzed Slice :", sliceN);
		if (!TPBLC) Dialog.addCheckbox("Circular integration analysis (CIA)", SDbd);
		if (!TPBLC) Dialog.addCheckbox("Median Filter", MedianFilt);
		Dialog.addCheckbox("Save list of analyzed images", LoAI);
		Dialog.addCheckbox("Save these parameters", sauvparamini);
		Dialog.addMessage("Copyright@2015-2016 F.GANNIER - C.PASQUALIN");
		Dialog.addHelp("http://pccv.univ-tours.fr/ImageJ/TTorg/help.html");
		Dialog.show();
		noise = Dialog.getNumber();
		periomin = Dialog.getNumber();
		periomax = Dialog.getNumber();
		if (!TPBLC) seuilsd = Dialog.getNumber();
		sliceN = Dialog.getNumber();
		if (!TPBLC) detectbsd = Dialog.getCheckbox();
		if (!TPBLC) MedianFilt = Dialog.getCheckbox();
		sauvlist = Dialog.getCheckbox();
		sauvparam = Dialog.getCheckbox();							
	}
	// dernière verif avant lancement
	waitForUser("Batch Mode","Analyse these "+nbImg+" Images ?\n(press [Esc] to abort analysis)");
	iniTime = getTime();
	
		if (!isOpen("Progression")) {
			run("Text Window...", "name=Progression width=15 height=0.5 monospaced");  
			selectWindow("Progression");
			setLocation(ScW-140,1);
		}
	
	for (b=1; b<nbImg+1; b++){
		print("[Progression]", "\n"+b+" / "+nbImg);
	// ouverture de l'image "b" image par recup du nom dans array[b]
		nom = ImgList[b-1];
		Ext.openImagePlus(directory+nom);
		if (isOpen(nom)) {
/*
// traitement puis fermeture de tout ce qui a été ouvert
*/
			if (sliceN>1) setSlice(sliceN);
			init_Common_values();
			if (pixelH != pixelW) exit("Image must have squared pixel:");
			if (Verbose) { 
				VerboseF ("=== Analyse Image "+b+" ===");
				VerboseF("File : " + nom_ori);
			}
			getStatistics(area_1, mean_1, min_1, max_1, std_1, histogram_1);	
			if (max_1 == 0) {
				if (Verbose == 1) VerboseF("No image");
			} else /**/{		
				if (MedianFilt) {
					if (Verbose) VerboseF ("Applying Median filter");
					run("Median...", "radius=2 slice");
				}
				selectWindow(nom);
				fftwin = Fenetre_fft(largeur,hauteur);

				selectWindow(""+nom+"");
				run("Select All");  run("Copy");  
				CloseW(nom);
				newImage(nom, Nbits+"-bit black", fftwin, fftwin, 1);
				run("Select All"); 
				// setForegroundColor(1, 1, 1); 	run("Fill", "slice");  
				run("Paste");
				if (Verbose) VerboseF ("Enhancing contrast");
				Normalize(Nbits,fftwin,fftwin);
						
				//création de la fenêtre de Hanning
				if (Verbose) VerboseF ("Determining Hanning window");
				Hanning_name = Hanning_window(fftwin);
				
				//multiplication de l'image par Hanning et renommage
				imageCalculator("Multiply create 32-bit", nom, Hanning_name);
				if (Nbits < 32) run(Nbits+"-bit");
				CloseW(nom);
				CloseW(Hanning_name);
				selectWindow("Result of "+nom+"");
				rename(nom);
							
				//on redefinit la taille correcte du pix
				selectWindow(nom);
				setLocation(1, 1, 400, 400);
				run("Properties...", "unit=micron pixel_width="+pixelH+" pixel_height="+pixelH+" voxel_depth=1");
						
				//réalisation de la FFT sur l'image
				if (Verbose) VerboseF ("Processing FFT");
			//			selectWindow(nom);
				run("FFT"); 
				setLocation(1, 401, 400, 400);

				//detection basée sur SD (nouvelle methode) = Integration circulaire CIA
				if (detectbsd==true) {
				// pour l'instant je n'implémente pas la méthode CIA
				}
				// ===================  analyse classique ==================
				run("Subtract Background...", "rolling=30");
				if (Verbose) VerboseF ("Determining window of analysis");
				//Création de la fenêtre d'analyse	
				//Calcul de l'emplacement dans la FFT de la fréquence voulue
				vartemp = fftwin * pixelH;
				//grand cercle (periode minimum) arrondi au pix superieur : variable grdraypix
				grdraypix = floor (vartemp/periomin) + 1;
				//petit cerlce pour espacement max (periode maximum) arrondi au pix inferieur : variable pttraypix
				pttraypix = floor (vartemp/periomax);
				//création de la zone de recherche
				tor(fftwin/2-grdraypix, fftwin/2-grdraypix, grdraypix*2,fftwin/2-pttraypix, fftwin/2-pttraypix, pttraypix*2);

				//selection des maxima-locaux pour visualisation
				vartemp = Create_results(1);
				freqcorr=getInfo("window.contents");
				run("Close");
				
				nomfen = "";// permet de creer la variable, meme si on ne s'en sert pas! 
				if (vartemp >= periomin) { //permet de ne rien ecrire s'il n'y a pas de pic detecté
					nomfen = ""+substring(nom, 0, lengthOf(nom)-4);
					nomfen2 = "["+nomfen+"]";
					run("Text Window...", "name="+nomfen+" width=72 height=10 monospaced");
					print(nomfen2,freqcorr);
					//sauvegarde du fichier (le fait qu'il soit ici permet de ne rien sauver s'il n'y a rien  d'ecrit
					saveAs("Text", ""+directory+""+nomfen+".txt");
				}
				//partie fermeture des fenetres:
				CloseW(nomfen+".txt");
				CloseW("FFT of "+nom+"");
			}
			CloseW(nom);
			if (Verbose) VerboseF ("Analyse of image "+b+" done");
		}
	// fin de la boucle d'analyse
	}
	// sauvegarde de SMZ
	SaveW("SMZ", "Results", directory+"SMZ.xls");
	Create_LogF();
	if (sauvparam==true) Save_Param();

	// sauvegarde de la liste des images traitées si demandé
	if (sauvlist){
		Array.show("LoAI", ImgList);
		saveAs("Results", directory+"LoAI.xls");
	}

	finTime = getTime();
	beep();
	waitForUser( "The end","Analyse complete !\n("+calcTime(iniTime, finTime)+")");
}

function SaveW(nom, type, filename) {
	if (isOpen(nom)) {
		if (Debug) VerboseF ("Saving "+nom);
		selectWindow(nom); 
		saveAs("Text", filename);
		return true;
	} else return false;
}

function Save_CloseW(nom, type, filename) {
	if (SaveW(nom, type, filename)) {
		if (Debug) VerboseF ("Closing "+nom);
		run("Close");	
		do { wait(10); } while (isOpen(nom));
	}
}

function CloseW(nom) {
	if (isOpen(nom)) {
		if (Debug) VerboseF ("Closing "+nom);
		selectWindow(nom); 
		run("Close");
		do { wait(10); } while (isOpen(nom));
	}
}

function Create_VerboseF() {
	if (!isOpen("VerboseW")) {
		run("New... ", "name=VerboseW type=text"); 
		selectWindow("VerboseW");
		setLocation(ScW-350,ScH-300);
	}
}

function VerboseF(txt) {
	print("[VerboseW]", txt);
}

function Normalize(bits, Hsize, Vsize) {
	getStatistics(area, mean, min, max, std, histogram);
	if (Verbose) VerboseF ("Min : "+min+" ; Max : "+max);
	if (Verbose) VerboseF ("XMax : "+Hsize+" ; YMax : "+Vsize);
	scale = 1.0;
	if ((max-min)>0.0)
		scale = pow(2,bits) /(max-min);	//		scale = 65535.0/(max-min);
	if (Verbose) VerboseF ("scale : "+ scale);
	if (scale >1.01) {
		for (i=0; i<Hsize; i++)
			for (j=0;j<Vsize;j++)
				setPixel(i, j, (getPixel(i,j)-min)*scale);
		resetMinAndMax();	
		if (Verbose) VerboseF ("Normalization done!");
	}
}

function Create_Smz() {
	if (!isOpen("SMZ")) {
		run("New... ", "name=SMZ type=Table");
		if (TPBLC) print("[SMZ]","\\Headings:Img file\tPower (AU)\tPeriod ("+unit+")\taccuracy ("+unit+")\tAngle ("+fromCharCode(0x00B0)+")"); 
		else print("[SMZ]","\\Headings:Img file\tPower (AU)\tPeriod ("+unit+")\taccuracy ("+unit+")\tAngle ("+fromCharCode(0x00B0)+")\tCIA (UA)"); 
		selectWindow("SMZ");
		if (isOpen("VerboseW"))
			setLocation(ScW-350,ScH-551);
		else setLocation(ScW-350,ScH-300);
	}
}

function Summurize_mode(smz){
	print("[SMZ]", smz);
}

function Create_LogF(){
	if (!isOpen("TT_Log")) {
		run("New... ", "name=TT_Log type=text"); 
	}
}

function LogF(txt){
	print("[TT_Log]", txt);
}

function Save_Param() {
	if (Verbose) VerboseF ("Saving parameters");
	LogF("Pixel size = "+d2s(pixelH,7));
	LogF("SSPD = "+noise);
	LogF("Minimum spacing = "+periomin);
	LogF("Maximum spacing = "+periomax);
	LogF("SD seuil = "+seuilsd);
	if (!TPBLC) LogF("Circular integration = "+detectbsd);
	LogF("Save list of analysed images = "+sauvlist);
	LogF("Save parameters = "+sauvparam);
	LogF("Median filter = "+MedianFilt);
	LogF("Close all = "+clausall);
	Save_CloseW("TT_Log", "Text", ""+directory+"parameter.txt");
}

function Create_roi(fftwin, tangledeg) {
	roiManager("Add");
// selection de l'angle
	tanglerad = PI * tangledeg / 180;
	toldist = tan(tanglerad) * fftwin/2;
	makePolygon(fftwin/2,fftwin/2,1,fftwin/2-toldist,1,fftwin/2+toldist);
	roiManager("Add");
	makePolygon(fftwin/2,fftwin/2,fftwin-1,fftwin/2-toldist,fftwin-1,fftwin/2+toldist); // a corriger pour autre coté c'est le "1" a remplacer par lcrop
	roiManager("Add");	
	roiManager("Select", newArray(0,1));
	roiManager("AND");
	roiManager("Add");
	roiManager("Select", newArray(0,2));
	roiManager("AND");
	roiManager("Add");
	roiManager("Select", newArray(3,4));
	roiManager("Combine");
}