package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	
	public class razmjena_mc extends MovieClip {
		var Monopoly:Igra;
		var FiguriceZaPrikaz:Vector.<figuricaOdabir_mc> = new Vector.<figuricaOdabir_mc>();  // grafički reprezentanti figurica za prikaz
		var IndeksOdabranogIgraca:uint;
		var IndeksiIgraca:Array = new Array(); // ovo polje sadržavat će indekse svih igrača koji nisu bankrotirali, tj. koji mogu sudjelovati u aukciji
		var MaleKarticePosjeda:Array = new Array();  // sastojat će se od objekata koji će imati svojstva "kartica" i "indeks"
		var MaleKarticeIzadjiIzZatvora:Array = new Array();
		var BrojTrenutnoOtvoreneKartice:uint;
		var KarticeZaRazmjenu:Array = new Array();  // ovo polje će čuvati indekse svih kartica koje su uključene u razmjenu
		var OdabraneKarticeLijevogIgraca:Vector.<String> = new Vector.<String>();
		var OdabraneKarticeDesnogIgraca:Vector.<String> = new Vector.<String>();
		var OdlukaAIIgraca:Boolean = false;

		public function razmjena_mc(monopoly:Igra) {
			Monopoly = monopoly;
			
			// najprije pretražujemo sve one igrače koji nisu bankrotirali (i koji nisu trenutni igrač)
			for (var i:uint = 0; i < igrac_mc.Igraci.length; i++)
				if (! igrac_mc.Igraci[i].Bankrotirao && i != igrac_mc.IgracNaPotezu)
					IndeksiIgraca.push(i);
			
			// potom izrađujemo prikaze svih figurica (deep copy)
			FiguriceZaPrikaz = Monopoly.FiguriceZaPrikaz.map(DeepCopy);  // kloniramo figurice za prikaz
			function DeepCopy(elem:figuricaOdabir_mc, indeks:int, vektor:Vector.<figuricaOdabir_mc>)
			{
				var objectClass:Class = Object(elem).constructor;
				var klonFigurice:figuricaOdabir_mc = new objectClass() as figuricaOdabir_mc;
				klonFigurice.gotoAndStop(elem.currentFrame);
				klonFigurice.transform = elem.transform;
				klonFigurice.filters = elem.filters;
				klonFigurice.Pozadina.transform = elem.Pozadina.transform;
				klonFigurice.Okvir.transform.colorTransform = Monopoly.CrnaOznakaFigurice;
				klonFigurice.buttonMode = true;
				klonFigurice.addEventListener(MouseEvent.CLICK, PostaviRazmjenu);
				return klonFigurice;
			}
			
			// ako ima više od 2 igrača, prikazujemo dijalog. u suprotnom postavljamo odmah aukciju (jer se zna koja će dva igrača sudjelovati u akuciji)
			if (IndeksiIgraca.length > 1) // znači da ima više od 2 igrača
				PrikaziDijalogOdabiraIgraca();
			else
				PostaviRazmjenu();
		}
		
		private function PrikaziDijalogOdabiraIgraca():void
		{
			var sirinaDijaloga:uint;			
			
			sirinaDijaloga = 40 + IndeksiIgraca.length * 100;  // širina dijaloga ovisit će o broju igrača koji sudjeluje u igri -> broj igrača koji nisu bankrotirali, izuzev igrača na potezu
			var dijalog:dijalog_mc = new dijalog_mc("Odaberite igrača \nza razmjenu:", sirinaDijaloga, 180);
			Monopoly.Kontejner.addChild(dijalog);
			dijalog.Odbij.visible = false;
			dijalog.Prihvati.visible = false;
			
			// postavljanje figurica igrača u polje "FiguriceZaPrikaz" i na dijalog
			var trenutniIndeksPrikazanogIgraca:uint = 0;  // ova će nam varijabla pomoći da figurice igrača smjestimo na dijalog. svaki puta kada stavimo novog igrača, njena će se vrijednost povećati
			
			// dodajemo figurice onih igrača koji nisu bankrotirali redom na dijalog (izuzev figurice igrača na potezu jer on ne smije moći ući u razmjenu sam sa sobom)
			for (var i:uint = 0; i < FiguriceZaPrikaz.length; i++)
			{
				if (IndeksiIgraca.indexOf(i) != -1) // ako je igrač s tom figuricom nije bankrotirao, dodat ćemo ga na dijalog
				{
					dijalog.DodajNaDijalog(FiguriceZaPrikaz[i], 0, sirinaDijaloga / ( -2) + 40 + trenutniIndeksPrikazanogIgraca * 100, 0);
					trenutniIndeksPrikazanogIgraca++;
				}
			}
		}
		
		private function PostaviRazmjenu(e:MouseEvent = null):void
		{
			const FRAME_S_GUMBOM_PRIHVACANJA:uint = 1;
			const FRAME_S_GUMBOM_ODBIJANJA:uint = 2;
			
			// najprije uklanjamo sve eventlistenere s gumba dijaloga
			for (var i:uint = 0; i < FiguriceZaPrikaz.length; i++)
				FiguriceZaPrikaz[i].removeEventListener(MouseEvent.CLICK, PostaviRazmjenu);
			
			// uklanjamo dijalog (ukoliko je instanciran)
			if (e != null)
				Monopoly.Kontejner.removeChild(e.currentTarget.parent);
			
			// ako su u aukciji sudjelovala samo dva igrača, tada je logično da moramo za drugu ikonu dodati ikonu drugog igrača. U suprotnom ćemo koristiti indexOf kako bi saznali indeks odabranog igrača za razmjenu
			if (IndeksiIgraca.length == 1)
				IndeksOdabranogIgraca = IndeksiIgraca[(IndeksiIgraca.indexOf(igrac_mc.IgracNaPotezu) + 1) % 2];
			else
				IndeksOdabranogIgraca = FiguriceZaPrikaz.indexOf(e.currentTarget);
			
			// dodajemo razmjenu na stage te ju podešavamo
			Monopoly.stage.addChild(this);
			this.Potvrdi.gotoAndStop(FRAME_S_GUMBOM_PRIHVACANJA);
			this.Potvrdi.buttonMode = true;
			this.Potvrdi.addEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.gotoAndStop(FRAME_S_GUMBOM_ODBIJANJA);
			this.Odbij.buttonMode = true;
			this.Odbij.addEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
			// dodajemo ikone igrača na razmjenu
			this.addChild(FiguriceZaPrikaz[igrac_mc.IgracNaPotezu]);
			FiguriceZaPrikaz[igrac_mc.IgracNaPotezu].x = 6;
			FiguriceZaPrikaz[igrac_mc.IgracNaPotezu].y = 6;
			FiguriceZaPrikaz[igrac_mc.IgracNaPotezu].scaleX = 1;
			FiguriceZaPrikaz[igrac_mc.IgracNaPotezu].scaleY = 1;
			FiguriceZaPrikaz[igrac_mc.IgracNaPotezu].buttonMode = false;
			this.addChild(FiguriceZaPrikaz[IndeksOdabranogIgraca]);
			FiguriceZaPrikaz[IndeksOdabranogIgraca].x = 595;
			FiguriceZaPrikaz[IndeksOdabranogIgraca].y = 6;
			FiguriceZaPrikaz[IndeksOdabranogIgraca].scaleX = 1;
			FiguriceZaPrikaz[IndeksOdabranogIgraca].scaleY = 1;
			FiguriceZaPrikaz[IndeksOdabranogIgraca].buttonMode = false;
			this.Novac1.text = igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac.toString() + "Kn";
			this.Novac2.text = igrac_mc.Igraci[IndeksOdabranogIgraca].Novac.toString() + "Kn";
			this.ImeFigurice1.text = igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Figurica.ImeFigurice;
			this.ImeFigurice2.text = igrac_mc.Igraci[IndeksOdabranogIgraca].Figurica.ImeFigurice;
			this.OdabraneKartice1.text = "";
			this.OdabraneKartice2.text = "";
			
			PostaviKarticeNaStol(true);  // ova metoda će postaviti sve kartice na stol za razmjenu, najprije od desnog igrača ...
			PostaviKarticeNaStol(false);  // ... a potom od lijevog
			PostaviKarticeIzadjiIzZatvora();
		}
		
		private function PostaviKarticeNaStol(desniIgrac:Boolean):void
		{
			const POCETNI_Y:uint = 115;
			const RAZMAK_KARTICA_ISTE_BOJE:uint = 20;  // ovaj razmak je vertikalni
			const RAZMAK_KARTICA_DRUGE_BOJE:uint = 52;  // ovaj razmak je horizontalni
			const RAZMAK_MEDJU_REDOVIMA:uint = 115;  // ovaj razmak je vertikanlni
			
			var pocetniX:uint = 454;  // zašto je ovo varijabla a ne konstanta? Zato jer ćemo ukoliko se radi o lijevom igraču morati korigirati tu vrijednost na 640 - početniX
			var indeksIgraca:uint = (desniIgrac == true) ? IndeksOdabranogIgraca : igrac_mc.IgracNaPotezu;
			var red:uint, stupac:uint;  // red i stupac će nam reći gdje točno pozicionirati karticu
			var smjerPozicioniranjaKartica:int = 1;  // ako se radi o desnom igraču, kartice ćemo slagati nadesno. U suprotnom (lijevi igrač), slagat ćemo ih nalijevo
			var brojKarticaNaPoziciji:Array = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);  // broj kartica koje su već poslagane za svaku boju. Inicijaliziramo elemente polja na nule
			
			// postavljanje kartica posjeda
			var tmpPosjed:Posjed;
			var tmpIndeks:uint;  // tmp indeks biti će indeks polja "brojKarticaNaPoziciji", ovisno o vrsti kartice koju bude trebalo postaviti na ploču
			var imaKucaNaPosjedu:Boolean;
			for (var i:uint = 0; i < Polje.Polja.length; i++)
			{
				if (Polje.Polja[i] is Posjed)
				{
					tmpPosjed = Polje.Polja[i] as Posjed;
					if (tmpPosjed is Zemljiste)
					{
						imaKucaNaPosjedu = false;
						// da bi posjed uopće ušao u razmatranje, na čitavoj njegovoj boji ne smije biti sagrađenih zgrada
						for (var j:uint = 0; j < Zemljiste.Zemljista.length; j++)
							if (Zemljiste.Zemljista[j].VrstaPolja == tmpPosjed.VrstaPolja && Zemljiste.Zemljista[j].BrojKuca > 0)
								imaKucaNaPosjedu = true;
								
						if (imaKucaNaPosjedu)
							continue;
					}
							
					if (tmpPosjed.Vlasnik == indeksIgraca)  // ako posjed pripada igraču za kojeg se ova funkcija izvršava ...
					{						
						switch (tmpPosjed.VrstaPolja)
						{
							case Polje.SMEDJE_POLJE: red = 0; stupac = 0; tmpIndeks = 0; break;
							case Polje.SVIJETLO_PLAVO_POLJE: red = 0; stupac = 1; tmpIndeks = 1; break;
							case Polje.ROZNO_POLJE: red = 0; stupac = 2; tmpIndeks = 2; break;
							case Polje.NARANCASTO_POLJE: red = 1; stupac = 0; tmpIndeks = 3; break;
							case Polje.CRVENO_POLJE: red = 1; stupac = 1; tmpIndeks = 4; break;
							case Polje.KOMUNALIJE_POLJE: red = 1; stupac = 2; tmpIndeks = 5; break;
							case Polje.ZELJEZNICKA_STANICA_POLJE: red = 1; stupac = 3; tmpIndeks = 6; break;
							case Polje.ZUTO_POLJE: red = 2; stupac = 0; tmpIndeks = 7; break;
							case Polje.ZELENO_POLJE: red = 2; stupac = 1; tmpIndeks = 8; break;
							case Polje.TAMNO_PLAVO_POLJE: red = 2; stupac = 2; tmpIndeks = 9; break;
						}
						
						if (! desniIgrac)  // ako se radi o lijevom igraču, tada moramo korigirati redak (jer su kartice lijevog i desnog igrača zrcalno simetrične)
						{
							if (red == 1)  // ako se radi o redu koji ima 4 karte u sebi (redu s indeksom 1)
								stupac = 3 - stupac;
							else  // ako se radi o redu koji ima 3 karte u sebi (redu s nekim drugim indeksom)
								stupac = 2 - stupac;
							
							pocetniX = 186; // tj. 640 - pocetniX => ako se radi o lijevom igraču, također korigiramo varijablu početniX
							smjerPozicioniranjaKartica = -1;  // ako se radi o lijevom igraču, kartice ćemo morati ravnati nalijevo
						}
						
						// potom izrađujemo kopiju kartice te ju postavljamo na ploču
						var malaKopijaKartice:karticaPosjeda_mc;
						if (! tmpPosjed.PodHipotekom) // ukoliko je posjed nije pod hipotekom, izrađujemo malu karticu posjeda. u suprotnom izrađujemo malu karticu hipoteke
							malaKopijaKartice = IzradiMaluKopijuKarticePosjeda(tmpPosjed.KarticaPosjeda);
						else
							malaKopijaKartice = IzradiMaluKopijuKarticePosjeda(tmpPosjed.KarticaHipoteke);
						
						this.addChild(malaKopijaKartice);
						malaKopijaKartice.x = pocetniX + stupac * RAZMAK_KARTICA_DRUGE_BOJE * smjerPozicioniranjaKartica;
						malaKopijaKartice.y = POCETNI_Y + red * RAZMAK_MEDJU_REDOVIMA + brojKarticaNaPoziciji[tmpIndeks] * RAZMAK_KARTICA_ISTE_BOJE;
						brojKarticaNaPoziciji[tmpIndeks]++;
						MaleKarticePosjeda.push({kartica: malaKopijaKartice, indeks: i});
					}
				}
			}
		}
		
		private function PostaviKarticeIzadjiIzZatvora():void
		{
			// postavljanje kartica izađite iz zatvora (potpuno ručno!). najprije izrađujemo za igrača na lijevoj strani, potom za igrača na desnoj strani
			var kartica:karticaSrece_mc;
			if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.length > 0)
			{
				kartica = IzradiMaluKopijuKarticeIzadjiIzZatvora(igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora[0]);
				MaleKarticeIzadjiIzZatvora.push({kartica: kartica, indeks:0, igrac:igrac_mc.IgracNaPotezu, uRazmjeni:false, otvorena:false});
				this.addChild(kartica);
				kartica.x = 176.70;
				kartica.y = 62;
				if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.length > 1)
				{
					kartica = IzradiMaluKopijuKarticeIzadjiIzZatvora(igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora[1]);
					MaleKarticeIzadjiIzZatvora.push( { kartica: kartica, indeks:1, igrac:igrac_mc.IgracNaPotezu, uRazmjeni:false, otvorena:false} );
					this.addChild(kartica);
					kartica.x = 142.70;
					kartica.y = 62;
				}
			}
			
			// potom za igrača na desnoj strani
			if (igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.length > 0)
			{
				kartica = IzradiMaluKopijuKarticeIzadjiIzZatvora(igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora[0]);
				MaleKarticeIzadjiIzZatvora.push({kartica: kartica, indeks:0, igrac:IndeksOdabranogIgraca, uRazmjeni:false, otvorena:false});
				this.addChild(kartica);
				kartica.x = 462;
				kartica.y = 62;
				if (igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.length > 1)
				{
					kartica = IzradiMaluKopijuKarticeIzadjiIzZatvora(igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora[1]);
					MaleKarticeIzadjiIzZatvora.push( { kartica: kartica, indeks:1, igrac:IndeksOdabranogIgraca, uRazmjeni:false, otvorena:false} );
					this.addChild(kartica);
					kartica.x = 492;
					kartica.y = 62;
				}
			}
		}
		
		private function Razmijeni(e:MouseEvent):void
		{
			if (parseInt(this.MojNovac.text) >= igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac || parseInt(this.NjegovNovac.text) >= igrac_mc.Igraci[IndeksOdabranogIgraca].Novac)
			{
				this.Objasnjenje.text = "Nemoguce obaviti razmjenu. Igraci nemaju toliko novca!"; 
				return;
			}
			
			// proverava se nude li oba igrača barem nešto. Prvo provjeravamo novac
			var prviIgracNudiBiloSto:Boolean = false, drugiIgracNudiBiloSto:Boolean = false;
			if (parseInt(this.MojNovac.text) > 0)
				prviIgracNudiBiloSto = true;
			if (parseInt(this.NjegovNovac.text) > 0)
				drugiIgracNudiBiloSto = true;
				
			// potom provjeravamo kartice posjeda
			for (var i:uint = 0; i < KarticeZaRazmjenu.length; i++)
			{
				if ((Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).Vlasnik == igrac_mc.IgracNaPotezu)
					prviIgracNudiBiloSto = true;
				if ((Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).Vlasnik == IndeksOdabranogIgraca)
					drugiIgracNudiBiloSto = true;
			}
			
			// a na kraju provjeravamo kartice izađi iz zatvora
			for (i = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
			{
				if (MaleKarticeIzadjiIzZatvora[i].igrac == igrac_mc.IgracNaPotezu)
					prviIgracNudiBiloSto = true;
				if (MaleKarticeIzadjiIzZatvora[i].igrac == IndeksOdabranogIgraca)
					drugiIgracNudiBiloSto = true;
			}
			
			if (! prviIgracNudiBiloSto || ! drugiIgracNudiBiloSto)
			{
				this.Objasnjenje.text = "Oba igrača moraju ponuditi najmanje jedno od ovoga: novac, karticu \"Izađite iz zatvora\" ili karticu posjeda.";
				return;
			}
			

			var ponudjeniNovacAI:uint, ponudjeniNovacOsoba:uint;
			if (this.NjegovNovac.text == "")
				ponudjeniNovacAI = 0;
			else
				ponudjeniNovacAI = parseInt(this.NjegovNovac.text);
				
			if (this.MojNovac.text == "")
				ponudjeniNovacOsoba = 0;
			else
				ponudjeniNovacOsoba = parseInt(this.MojNovac.text);
				
			if (igrac_mc.Igraci[IndeksOdabranogIgraca].AIIgrac)
				OdlukaAIIgraca = (igrac_mc.Igraci[IndeksOdabranogIgraca] as AI).OdlukaORazmjeni(KarticeZaRazmjenu, MaleKarticeIzadjiIzZatvora, ponudjeniNovacAI, ponudjeniNovacOsoba, IndeksOdabranogIgraca, igrac_mc.IgracNaPotezu);
			
			// ako je AI odlučio da ne želi razmjenu, ispisat ćemo to u dijalogu
			var dijalog:dijalog_mc;
			if (igrac_mc.Igraci[IndeksOdabranogIgraca].AIIgrac && ! OdlukaAIIgraca)
			{
				dijalog = new dijalog_mc("AI je odbio vašu ponudu.", 320, 240, 320, 240);
				this.addChild(dijalog);
				dijalog.UkloniGumbX();
				dijalog.Prihvati.addEventListener(MouseEvent.CLICK, ZatvoriDijalogAIOdluke);
			}
			
			// započinjemo s razmjenom 
			if (igrac_mc.Igraci[IndeksOdabranogIgraca].AIIgrac && OdlukaAIIgraca || ! igrac_mc.Igraci[IndeksOdabranogIgraca].AIIgrac)
			{
				// najprije kartice posjeda
				for (i = 0; i < KarticeZaRazmjenu.length; i++)
				{
					if ((Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).Vlasnik == igrac_mc.IgracNaPotezu)
					{
						(Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).Vlasnik = IndeksOdabranogIgraca;
						(Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).PostaviOznakuKupovine(igrac_mc.Igraci[IndeksOdabranogIgraca], KarticeZaRazmjenu[i]);
					} else
					{
						(Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).Vlasnik = igrac_mc.IgracNaPotezu;
						(Polje.Polja[KarticeZaRazmjenu[i]] as Posjed).PostaviOznakuKupovine(igrac_mc.Igraci[igrac_mc.IgracNaPotezu], KarticeZaRazmjenu[i]);
					}
				}
				
				// potom razmjenjujemo novac iz okvirića koji su uneseni
				if (this.MojNovac.text != "")
				{
					igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= parseInt(this.MojNovac.text);
					igrac_mc.Igraci[IndeksOdabranogIgraca].Novac += parseInt(this.MojNovac.text);
				}
				if (this.NjegovNovac.text != "")
				{
					igrac_mc.Igraci[IndeksOdabranogIgraca].Novac -= parseInt(this.NjegovNovac.text);
					igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac += parseInt(this.NjegovNovac.text);
				}
				
				// i na kraju razmjenjujemo kartice izađi iz zatvora
				var kartica:karticaSrece_mc;
				for (i = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
				{
					if (MaleKarticeIzadjiIzZatvora[i].uRazmjeni)
					{
						if (MaleKarticeIzadjiIzZatvora[i].igrac == igrac_mc.IgracNaPotezu)
						{
							if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.length == 1 && MaleKarticeIzadjiIzZatvora[i].indeks == 1)
								MaleKarticeIzadjiIzZatvora[i].indeks = 0;  // ovaj nam je IF potreban jer se korištenjem splice-a indeksi mogu pobrkati, pa onda indeks (property) male kartice izađi iz zatvora neće odgovarati indeksu velike kartice u polju igraca. Zbog toga ga korigiramo
							kartica = (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.splice(MaleKarticeIzadjiIzZatvora[i].indeks, 1))[0];
							igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.push(kartica);
						} else
						{
							if (igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.length == 1 && MaleKarticeIzadjiIzZatvora[i].indeks == 1)
								MaleKarticeIzadjiIzZatvora[i].indeks = 0;
							kartica = (igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.splice(MaleKarticeIzadjiIzZatvora[i].indeks, 1))[0];
							igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.push(kartica);
						}
					}
				}
				
				UkloniSveListenere();
				dijalog = new dijalog_mc("AI je prihvatio vašu ponudu.", 320, 240, 320, 240);
				this.addChild(dijalog);
				dijalog.UkloniGumbX();
				dijalog.Prihvati.addEventListener(MouseEvent.CLICK, ZatvoriDijalogAIOdluke);
			}
		}
		
		private function OdustaniOdRazmjene(e:MouseEvent):void
		{
			UkloniSveListenere();
			this.stage.removeChild(this);
		}
		
		private function UkloniSveListenere():void
		{
			this.Potvrdi.removeEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.removeEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
			
			// uklanjamo listenere sa svih malih kartica posjeda
			for (var i:uint = 0; i < MaleKarticePosjeda.length; i++)
				MaleKarticePosjeda[i].kartica.removeEventListener(MouseEvent.CLICK, OtvoriKarticuPosjeda);
				
			// uklanjamo listenere sa svih malih kartica "izađite iz zatvora"
			for (i = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
				MaleKarticeIzadjiIzZatvora[i].kartica.removeEventListener(MouseEvent.CLICK, OtvoriKarticuIzadjiIzZatvora);
			
			// ovdje također moramo ukloniti i žute okviriće s velikih kartica posjeda
			for (i = 0; i < Polje.Polja.length; i++)
			{
				if (Polje.Polja[i] is Posjed)
				{
					(Polje.Polja[i] as Posjed).KarticaHipoteke.filters = new Array();
					(Polje.Polja[i] as Posjed).KarticaPosjeda.filters = new Array();
				}
			}
			
			// uklanjamo i žute okviriće s velikih kartica "izađite iz zatvora"
			for (i = 0; i < igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.length; i++)
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora[i].filters = new Array();
			for (i = 0; i < igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora.length; i++)
				igrac_mc.Igraci[IndeksOdabranogIgraca].KarticeIzadjiIzZatvora[i].filters = new Array();
		}
		
		private function IzradiMaluKopijuKarticePosjeda(originalKartica:karticaPosjeda_mc):karticaPosjeda_mc
		{
			const FRAME_KARTICE_ZEMLJISTA:uint = 1;
			const FRAME_KARTICE_ZELJEZNICE:uint = 2;
			const FRAME_KARTICE_HIPOTEKE:uint = 5;
			var objectClass:Class = Object(originalKartica).constructor;
			var kopijaKartice:karticaPosjeda_mc = new objectClass() as karticaPosjeda_mc;
			kopijaKartice.gotoAndStop(originalKartica.currentFrame);
			kopijaKartice.transform = originalKartica.transform;
			kopijaKartice.filters = originalKartica.filters;
			kopijaKartice.scaleX = 0.255;
			kopijaKartice.scaleY = 0.255;
			kopijaKartice.buttonMode = true;
			kopijaKartice.addEventListener(MouseEvent.CLICK, OtvoriKarticuPosjeda);
			
			if (originalKartica.currentFrame == FRAME_KARTICE_ZEMLJISTA)
			{
				kopijaKartice.Naziv.text = originalKartica.Naziv.text;
				kopijaKartice.Boja.transform.colorTransform = originalKartica.Boja.transform.colorTransform;
				kopijaKartice.Najamnina.text = originalKartica.Najamnina.text;
				kopijaKartice.JednaKuca.text = originalKartica.JednaKuca.text;
				kopijaKartice.DvijeKuce.text = originalKartica.DvijeKuce.text;
				kopijaKartice.TriKuce.text = originalKartica.TriKuce.text;
				kopijaKartice.CetiriKuce.text = originalKartica.CetiriKuce.text;
				kopijaKartice.Hotel.text = originalKartica.Hotel.text;
				kopijaKartice.CijenaKuce.text = originalKartica.CijenaKuce.text;
				kopijaKartice.CijenaHotela.text = originalKartica.CijenaHotela.text;
				kopijaKartice.VrijednostHipoteke.text = originalKartica.VrijednostHipoteke.text;
			}
			
			if (originalKartica.currentFrame == FRAME_KARTICE_ZELJEZNICE)
				kopijaKartice.Naziv.text = originalKartica.Naziv.text;
				
			if (originalKartica.currentFrame == FRAME_KARTICE_HIPOTEKE)
			{
				kopijaKartice.NazivPosjeda.text = originalKartica.NazivPosjeda.text;
				kopijaKartice.VrijednostHipoteke.text = originalKartica.VrijednostHipoteke.text;
			}
			kopijaKartice.mouseChildren = false;
			
			return kopijaKartice;
		}
		
		private function IzradiMaluKopijuKarticeIzadjiIzZatvora(originalKartica:karticaSrece_mc):karticaSrece_mc
		{
			var objectClass:Class = Object(originalKartica).constructor;
			var kopijaKartice:karticaSrece_mc = new objectClass() as karticaSrece_mc;
			kopijaKartice.gotoAndStop(3);
			kopijaKartice.transform = originalKartica.transform;
			kopijaKartice.filters = originalKartica.filters;
			kopijaKartice.cacheAsBitmap = originalKartica.cacheAsBitmap;
			kopijaKartice.opaqueBackground = originalKartica.opaqueBackground;
			kopijaKartice.scaleX = 0.15;
			kopijaKartice.scaleY = 0.15;
			kopijaKartice.buttonMode = true;
			kopijaKartice.addEventListener(MouseEvent.CLICK, OtvoriKarticuIzadjiIzZatvora);
			kopijaKartice.TipKartice.text = originalKartica.TipKartice.text;
			kopijaKartice.IzadjiteIzZatvora.text = originalKartica.IzadjiteIzZatvora.text;
			kopijaKartice.Tekst.text = originalKartica.Tekst.text;
			kopijaKartice.mouseChildren = false;
			return kopijaKartice;
		}
		
		private function OtvoriKarticuPosjeda(e:MouseEvent):void
		{
			// kada se otvori kartica, isključujemo mogućnost gumba za prihvaćanje / odbijanje
			this.Potvrdi.removeEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.removeEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
			
			// najprije pronalazimo indeks polja kartice
			for (var i:uint = 0; i < MaleKarticePosjeda.length; i++)
				if (MaleKarticePosjeda[i].kartica == e.currentTarget as karticaPosjeda_mc)
					BrojTrenutnoOtvoreneKartice = MaleKarticePosjeda[i].indeks;
					
			// potom prikazujemo jedan veliki prozirni nevidljivi kvadrat preko cijelog ekrana. kad se na njega klikne, zatvorit će se kartica. U prijevodu, kada se klikne izvan kartice, ona se zatvara
			var izvanKatrice:Sprite = new Sprite();
			this.addChild(izvanKatrice);
			izvanKatrice.graphics.beginFill(0x555555, 0.3);
			izvanKatrice.graphics.drawRect(0, 0, 640, 480);
			izvanKatrice.graphics.endFill();
			izvanKatrice.addEventListener(MouseEvent.CLICK, ZatvoriKarticuPosjeda);
			
			// potom prikazujemo veliku karticu na ekranu
			var velikaKartica:karticaPosjeda_mc;
			if (! (Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).PodHipotekom)
				velikaKartica = (Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaPosjeda;
			else
				velikaKartica = (Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaHipoteke;
				
			this.addChild(velikaKartica);
			velikaKartica.x = 320;
			velikaKartica.y = 240;
			velikaKartica.buttonMode = true;
			velikaKartica.addEventListener(MouseEvent.CLICK, PostaviZutiOkvirOkoKarticePosjeda);
		}
		
		private function OtvoriKarticuIzadjiIzZatvora(e:MouseEvent):void
		{
			// kada se otvori kartica, isključujemo mogućnost gumba za prihvaćanje / odbijanje
			this.Potvrdi.removeEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.removeEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
			
			// potom prikazujemo jedan veliki prozirni nevidljivi kvadrat preko cijelog ekrana. kad se na njega klikne, zatvorit će se kartica. U prijevodu, kada se klikne izvan kartice, ona se zatvara
			var izvanKatrice:Sprite = new Sprite();
			this.addChild(izvanKatrice);
			izvanKatrice.graphics.beginFill(0x0, 0);
			izvanKatrice.graphics.drawRect(0, 0, 640, 480);
			izvanKatrice.graphics.endFill();
			izvanKatrice.addEventListener(MouseEvent.CLICK, ZatvoriKarticuIzadjiIzZatvora);
			
			// tražimo objekt kartice na koju smo kliknuli
			var malaKartica:Object;
			for (var i:uint = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
				if (MaleKarticeIzadjiIzZatvora[i].kartica == (e.currentTarget as karticaSrece_mc))
					malaKartica = MaleKarticeIzadjiIzZatvora[i];
				
			// potom prikazujemo veliku karticu na ekranu
			var velikaKartica:karticaSrece_mc = igrac_mc.Igraci[malaKartica.igrac].KarticeIzadjiIzZatvora[malaKartica.indeks];
			this.addChild(velikaKartica);
			malaKartica.otvorena = true;
			velikaKartica.x = 320;
			velikaKartica.y = 240;
			velikaKartica.buttonMode = true;
			velikaKartica.addEventListener(MouseEvent.CLICK, PostaviZutiOkvirOkoKarticeZatvora);
		}
		
		private function PostaviZutiOkvirOkoKarticePosjeda(e:MouseEvent):void  // ova funkcija služi za postavljanje i uklanjanje žutog okvira kada se klikne na karticu. ali i TAKOĐER za bilježenje aktivnih kartica za razmjenu
		{
			// pronalazimo malu karticu u polju malih kartica
			var malaKartica:Object;
			var zutiOkviricPostavljen:Boolean = false;
			for (var i:uint = 0; i < MaleKarticePosjeda.length; i++)
				if (MaleKarticePosjeda[i].indeks == BrojTrenutnoOtvoreneKartice)
					malaKartica = MaleKarticePosjeda[i];
			
			if ((e.currentTarget as karticaPosjeda_mc).filters.length == 0)
			{
				(e.currentTarget as karticaPosjeda_mc).filters = new Array(new GlowFilter(0xFFFF00, 1, 8, 8, 8));	
				malaKartica.kartica.filters = new Array(new GlowFilter(0xFFFF00, 1, 4, 4, 4));
				KarticeZaRazmjenu.push(BrojTrenutnoOtvoreneKartice);
				zutiOkviricPostavljen = true;
			} else
			{
				(e.currentTarget as karticaPosjeda_mc).filters = new Array();
				malaKartica.kartica.filters = new Array();
				KarticeZaRazmjenu.splice(KarticeZaRazmjenu.indexOf(BrojTrenutnoOtvoreneKartice), 1);
			}
			
			if (zutiOkviricPostavljen)
			{
				if ((Polje.Polja[malaKartica.indeks] as Posjed).Vlasnik == igrac_mc.IgracNaPotezu)
					OdabraneKarticeLijevogIgraca.push((Polje.Polja[malaKartica.indeks] as Posjed).NazivPolja);
				else
					OdabraneKarticeDesnogIgraca.push((Polje.Polja[malaKartica.indeks] as Posjed).NazivPolja);

			} else
			{
				if ((Polje.Polja[malaKartica.indeks] as Posjed).Vlasnik == igrac_mc.IgracNaPotezu)
					OdabraneKarticeLijevogIgraca.splice(OdabraneKarticeLijevogIgraca.indexOf((Polje.Polja[malaKartica.indeks] as Posjed).NazivPolja), 1);
				else
					OdabraneKarticeDesnogIgraca.splice(OdabraneKarticeDesnogIgraca.indexOf((Polje.Polja[malaKartica.indeks] as Posjed).NazivPolja), 1);
			}
			
			IspuniOkvririceOdabranihKartica();  // ova metoda će popuniti okviriće posjeda (i kartica "izađi iz zatvora") koji su trenutno označeni za razmjenu
		}
		
		private function PostaviZutiOkvirOkoKarticeZatvora(e:MouseEvent):void
		{
			var malaKartica:Object;
			var zutiOkviricPostavljen:Boolean = false;
			// najprije pronalazimo malu karticu izađi iz zatvora koja je otvorena
			for (var i:uint = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
				if (MaleKarticeIzadjiIzZatvora[i].otvorena)
					malaKartica = MaleKarticeIzadjiIzZatvora[i];
			
			if ((e.currentTarget as karticaSrece_mc).filters.length == 0)
			{
				(e.currentTarget as karticaSrece_mc).filters = new Array(new GlowFilter(0xFFFF00, 1, 8, 8, 8));	
				malaKartica.kartica.filters = new Array(new GlowFilter(0xFFFF00, 1, 4, 4, 4));
				malaKartica.uRazmjeni = true;
				zutiOkviricPostavljen = true;
			} else
			{
				(e.currentTarget as karticaSrece_mc).filters = new Array();
				malaKartica.kartica.filters = new Array();
				malaKartica.uRazmjeni = false;
			}
			
			if (zutiOkviricPostavljen)
			{
				if (malaKartica.igrac == igrac_mc.IgracNaPotezu)
					OdabraneKarticeLijevogIgraca.push("Kartica \"Izađite iz zatvora\"");
				else
					OdabraneKarticeDesnogIgraca.push("Kartica \"Izađite iz zatvora\"");
			} else
			{
				if (malaKartica.igrac == igrac_mc.IgracNaPotezu)
					OdabraneKarticeLijevogIgraca.splice(OdabraneKarticeLijevogIgraca.indexOf("Kartica \"Izađite iz zatvora\""), 1);
				else
					OdabraneKarticeDesnogIgraca.splice(OdabraneKarticeDesnogIgraca.indexOf("Kartica \"Izađite iz zatvora\""), 1);
			}
			
			IspuniOkvririceOdabranihKartica();  // ova metoda će popuniti okviriće posjeda (i kartica "izađi iz zatvora") koji su trenutno označeni za razmjenu
		}
		
		private function ZatvoriKarticuPosjeda(e:MouseEvent):void
		{
			// uklanjamo nevidljivi pravokutnik i listener s njega
			e.currentTarget.removeEventListener(MouseEvent.CLICK, ZatvoriKarticuPosjeda);
			this.removeChild(e.currentTarget as Sprite);
			
			// uklanjamo karticu s ekrana koja se pojavila
			if ((Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).PodHipotekom)
			{
				(Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaHipoteke.buttonMode = false;
				(Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaHipoteke.removeEventListener(MouseEvent.CLICK, PostaviZutiOkvirOkoKarticePosjeda);
				this.removeChild((Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaHipoteke);
			} else
			{
				(Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaPosjeda.buttonMode = false;
				(Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaPosjeda.removeEventListener(MouseEvent.CLICK, PostaviZutiOkvirOkoKarticePosjeda);
				this.removeChild((Polje.Polja[BrojTrenutnoOtvoreneKartice] as Posjed).KarticaPosjeda);
			}
			
			// ponovno omogućujemo gumbe Potvrdi / Odbij
			this.Potvrdi.addEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.addEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
		}
		
		private function ZatvoriKarticuIzadjiIzZatvora(e:MouseEvent):void
		{			
			// uklanjamo nevidljivi pravokutnik i listener s njega
			e.currentTarget.removeEventListener(MouseEvent.CLICK, ZatvoriKarticuPosjeda);
			this.removeChild(e.currentTarget as Sprite);
			
			// potom pronalazimo karticu koja je upravo otvorena
			var malaKartica:Object;
			for (var i:uint = 0; i < MaleKarticeIzadjiIzZatvora.length; i++)
				if (MaleKarticeIzadjiIzZatvora[i].otvorena)
					malaKartica = MaleKarticeIzadjiIzZatvora[i];
			
			// uklanjamo karticu s ekrana koja se pojavila i listener s nje
			this.removeChild(igrac_mc.Igraci[malaKartica.igrac].KarticeIzadjiIzZatvora[malaKartica.indeks]);
			igrac_mc.Igraci[malaKartica.igrac].KarticeIzadjiIzZatvora[malaKartica.indeks].removeEventListener(MouseEvent.CLICK, PostaviZutiOkvirOkoKarticeZatvora);
			malaKartica.otvorena = false;
			
			// ponovno omogućujemo gumbe Potvrdi / Odbij
			this.Potvrdi.addEventListener(MouseEvent.CLICK, Razmijeni);
			this.Odbij.addEventListener(MouseEvent.CLICK, OdustaniOdRazmjene);
		}
		
		private function IspuniOkvririceOdabranihKartica():void  // ova metoda će popuniti okviriće posjeda (i kartica "izađi iz zatvora") koji su trenutno označeni za razmjenu
		{
			OdabraneKartice1.text = "";
			OdabraneKartice2.text = "";
			
			for (var i:uint = 0; i < OdabraneKarticeLijevogIgraca.length; i++)
			{
 				OdabraneKartice1.appendText(OdabraneKarticeLijevogIgraca[i]);
				
				if (i != OdabraneKarticeLijevogIgraca.length - 1)
					OdabraneKartice1.appendText(", ");
			}
			
			for (i = 0; i < OdabraneKarticeDesnogIgraca.length; i++)
			{
				OdabraneKartice2.appendText(OdabraneKarticeDesnogIgraca[i]);
				
				if (i != OdabraneKarticeDesnogIgraca.length - 1)
					OdabraneKartice2.appendText(", ");
			}
		}
		
		private function ZatvoriDijalogAIOdluke(e:MouseEvent):void
		{
			e.currentTarget.parent.removeEventListener(MouseEvent.CLICK, ZatvoriDijalogAIOdluke);
			this.removeChild(e.currentTarget.parent);
			if (OdlukaAIIgraca)
				this.stage.removeChild(this);
		}
	}
}