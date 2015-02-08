package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	public class figurica_mc extends MovieClip {
		private const POCETNI_X:uint = 440;	// 440 px
		private const VANJSKI_DIO_PLOCE:uint = 420;	// = početna y koordinata
		private const RAZMAK_MEDJU_FIGURICAMA:uint = 12;
		private const SIRINA_VELIKOG_POLJA:uint = 50;
		private const SIRINA_MALOG_POLJA:uint = 37;
		private const VELIKO_POLJE = 0;
		private const DOLJE:uint = 0, LIJEVO:uint = 1, GORE:uint = 2, DESNO:uint = 3;
		private const UKUPAN_BROJ_POLJA:uint = 40;
		private const POMAK_PO_FRAMEU:uint = 10; 
		private const RUBNA_POZICIJA:uint = 440; // = POCETNI_X. Označava (u pixelima) krajnju desnu ili donju poziciju do koje se na ploči može ići
		private const FAKTOR_ZOOMIRANJA_PLOCE:uint = 3;
		private var Monopoly:Igra;
		public var BrojFigurice:uint;
		public var ImeFigurice:String;
		private var PreostaloPolja:int;	// označava koliko se još polja moramo pomaknuti (s obzirom na očitanje s kockica)
		private var StranaPolja:uint = DOLJE;
		public var Pozicija:uint = 0;	// broj između 0 i 40. Označava indeks polja na ploči
		private var StaraPozicija:uint = 0;
		public static var BijeliPrsten:prsten_mc;
		private var PocetnaRotacija:int = 360;  // mora biti neki broj koji nije između -180 i 180
		private var PlocaZoomirana:Boolean = false;  // pročitaj objašnjenje u "ZarotirajSeZa180"
		private var OdmakOdRuba:uint;

		public function figurica_mc(brojFigurice:uint) {
			BrojFigurice = brojFigurice;
			DodijeliFiguriciIme();
			this.addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			Monopoly = this.parent.parent.parent.parent as Igra;
			var indeksFigurice:uint;  // == indeksu igrača
			gotoAndStop(BrojFigurice);
			
			this.x = POCETNI_X;
			
			//pronalazimo indeks figurice
			for (var i:uint = 0; i < igrac_mc.Igraci.length; i++)
				if (igrac_mc.Igraci[i].Figurica == this)
					indeksFigurice = i;
					
			// pronalazimo gdje figuricu na y osi treba pozicionirati (yOffset označava koliko ju trebamo pomaknuti od početne pozicije
			if (indeksFigurice > 0)
			{
				var yOffset:Number = igrac_mc.Igraci[0].Figurica.height + 1;
				for (i = 1; i < indeksFigurice; i++)
					yOffset += igrac_mc.Igraci[i].Figurica.height + 1;
				yOffset += this.height / 2;
			} else
			{
				yOffset = this.height / 2;  // prvu figuricu pomičemo samo pola njezine visine piksela dolje (kako ne bi prelazila preko boja zemljišta i prolazila "kroz" hotele koje ćemo kasnije stavljati)
			}
			
			// određujemo početnu y poziciju figurice
			this.y = VANJSKI_DIO_PLOCE + yOffset;
			OdmakOdRuba = 480 - this.y;
			
			name = "igrac" + indeksFigurice;
			
			// dodajemo prsten oko prvog igrača na potezu (dakle, samo jednom)
			if (BijeliPrsten == null)
			{
				BijeliPrsten = new prsten_mc (this.x, this.y);
				Monopoly.KontejnerIgre.addChild(BijeliPrsten);
			}
		}
		
		public function PomakniFiguricu(pomak:int):void
		{
			var tajmer:Timer = new Timer(700, 1);
			
			PreostaloPolja = pomak;
			
			tajmer.addEventListener(TimerEvent.TIMER, PomiciFiguricu);
			tajmer.start();
			function PomiciFiguricu (e:TimerEvent):void
			{
				tajmer.removeEventListener(TimerEvent.TIMER, PomiciFiguricu);
				tajmer.stop();
				// uklanjamo bijeli prsten oko igrača
				BijeliPrsten.UkloniPrstenOkoIgraca();
				if (! PlocaZoomirana)
					ZoomirajPlocu(FAKTOR_ZOOMIRANJA_PLOCE);
				Monopoly.KontejnerIgre.addEventListener(Event.ENTER_FRAME, PomiciPlocu);
				addEventListener(Event.ENTER_FRAME, PomiciPostupno);
			}			
		}
		
		public function PomakniFiguricuNatrag(pomak:int):void
		{
			PomakniFiguricu(pomak * ( -1));
		}
		
		private function PomiciPostupno(e:Event):void
		{
			const NA_POLJU_KRENI:uint = 0;
			var smjerPomicanja:int;		// može biti -1 ili 1, ovisno o tome, smanjuje li se ili povećava x ili y os
			var igracUZatvoru:Boolean = ((this.parent as igrac_mc).UZatvoru == null ? false : true);  // ako je igrač (vlasnik ove figurice) u zatvoru, ova će varijabla biti TRUE
			
			// ako se figurica nalazi dolje ili lijevo, treba se pomicati u negativnom smjeru (smanjenje piksela na x ili y osi). U suportnom, u pozitivnom
			if (StranaPolja == DOLJE || StranaPolja == LIJEVO)
				smjerPomicanja = -1;
			else
				smjerPomicanja = 1;
				
			if (PreostaloPolja < 0)  // ako je broj preostalih polja manji od nule to znači da se figurica kreće unatrag. Da bi se figurica mogla kretati unatrag, obrćemo smjer pomicanja
				smjerPomicanja *= -1;
			
			// nakon što znamo smjer pomicanja, slijedi samo pomicanje
			if (PreostaloPolja != 0)
			{
				var sljedecePolje:Boolean;
				
				// osnovno jednostavno pravocrtno pomicanje
				if (StranaPolja == DOLJE || StranaPolja == GORE)
					this.x += POMAK_PO_FRAMEU * smjerPomicanja;
				else	// ako je lijevo ili desno
					this.y += POMAK_PO_FRAMEU * smjerPomicanja;
				
				// pozivamo funkciju koja provjerava jesmo li stali na sljedeće polje, ovisno o tome krećemo li se na ploči naprijed ili natrag
				if (PreostaloPolja > 0)
					sljedecePolje = ProvjeriJelSljedecePolje(1);
				else
					sljedecePolje = ProvjeriJelSljedecePolje( -1);
				
				if (sljedecePolje)
				{
					// ako smo tijekom pomicanja u jednom frame-u zagazili na novo polje, povećavamo poziciju (ili smanjujemo ukoliko se krećemo unatrag) i smanjujemo broj preostalih polja za preći (onih s kockica)
					if (PreostaloPolja > 0)
					{
						Pozicija = (Pozicija + 1) % 40;
						PreostaloPolja--;
					} else
					{
						Pozicija = (Pozicija - 1 + 40) % 40;
						PreostaloPolja++;
					}
					
					if (Pozicija == NA_POLJU_KRENI && ! igracUZatvoru) // kada igrač tijekom kretanja stane na polje KRENI (a nije u zatvoru), dodjeljujemo mu 4000 kn
						igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac += 4000;
					
					
					// ako se nalazimo na posljednjem polju na jednoj strani
					if (Pozicija % 10 == 0)
					{
						// uklanjamo listener za pomicanje i dodajemo listener za rotiranje figurice
						removeEventListener(Event.ENTER_FRAME, PomiciPostupno);
						addEventListener(Event.ENTER_FRAME, ZarotirajSe);
					}
				}
			}
			else
			{
				// nakon što je figurica stala, moramo dodati bijeli prsten na novo mjesto gdje je stala
				BijeliPrsten = new prsten_mc (this.x, this.y);
				Monopoly.KontejnerIgre.addChild(BijeliPrsten);
				
				// prestajemo s pomicanjem na ploči
				removeEventListener(Event.ENTER_FRAME, PomiciPostupno);
				// šaljemo event da je figurica stigla na odredište
				this.dispatchEvent(new Event("Figurica stigla na polje")); 
			}
		}
		
		private function ProvjeriJelSljedecePolje(smjerKretanja:int):Boolean  // provjeravamo je li figurica stala na sljedeće polje, s obzirom na to jel se kreće naprijed ili unatrag
		{
			// provjerava je li figurica zagazila na sljedeće polje
			
			// označava trenutnu poziciju (0-9) na nekoj strani polja (L,D,G,D)
			var trenutnaPozicijaNaStraniPolja:uint = Pozicija % 10;
			var SredinaPolja:Point = Polje.Polja[(Pozicija + 40 + smjerKretanja) % 40].VratiSredinuPolja();
			
			var uvjet:Boolean = (smjerKretanja == 1) ? (trenutnaPozicijaNaStraniPolja < 9) : (trenutnaPozicijaNaStraniPolja > 1 || trenutnaPozicijaNaStraniPolja == 0);
			var tmpOdmakOdruba:uint = (smjerKretanja == 1) ? OdmakOdRuba : (480 - OdmakOdRuba);
			
			switch (StranaPolja)
			{
				case DOLJE:
					// kada razlika između sredine idućeg polja i trenutne lokacije bude 5 piksela
					if (uvjet)
					{
						if (Math.abs(this.x - SredinaPolja.x) <= 5)
							return true;
					} else
					{
						if (Math.abs(this.x - tmpOdmakOdruba) <= 5)
							return true;
					}
					break;
				case LIJEVO:
					if (uvjet)
					{
						if (Math.abs(this.y - SredinaPolja.y) <= 5)
							return true;
					} else
					{
						if (Math.abs(this.y - tmpOdmakOdruba) <= 5)
							return true;
					}
					break;
				case GORE:
					if (uvjet)
					{
						if (Math.abs(this.x - SredinaPolja.x) <= 5)
							return true;
					} else
					{
						if (Math.abs(this.x - (480 - tmpOdmakOdruba)) <= 5)
							return true;
					}
					break;
				case DESNO:
					if (uvjet)
					{
						if (Math.abs(this.y - SredinaPolja.y) <= 5)
							return true;
					} else
					{
						if (Math.abs(this.y - (480 - tmpOdmakOdruba)) <= 5)
							return true;
					}
					break;
			}
			
			return false;
		}
		
		private function ZarotirajSe(e:Event)
		{
			// ako se figurica kreće unatrag (broj preostalih polja < 0), okrećemo smjer rotacije
			var smjerRotacije:int;
			if (PreostaloPolja >= 0)
				smjerRotacije = 1;
			else
				smjerRotacije = -1;
			
			const ROTACIJA_PO_FRAMEU:uint = 15;
			var uvjetRotacije:Boolean;
			switch (StranaPolja)
			{
				case DOLJE:
					uvjetRotacije = (smjerRotacije == 1) ? (rotation < 90) : (rotation == -180 || rotation > 90);
					break;
				case LIJEVO:
					uvjetRotacije = (smjerRotacije == 1) ? (rotation < 180) : (rotation > -180);
					break;
				case GORE:
					uvjetRotacije = (smjerRotacije == 1) ? (rotation < -90 || rotation == 180) : (rotation > -90);
					break;
				case DESNO:
					uvjetRotacije = (smjerRotacije == 1) ? (rotation < 0) : (rotation > 0);
					break;
			}
			
			if (uvjetRotacije)
			{
				rotation += ROTACIJA_PO_FRAMEU * smjerRotacije;
			}
			else
			{
				if (smjerRotacije == 1)
					StranaPolja = (StranaPolja + 1) % 4;
				else
					StranaPolja = (StranaPolja + 4 - 1) % 4;
					
				removeEventListener(Event.ENTER_FRAME, ZarotirajSe);
				addEventListener(Event.ENTER_FRAME, PomiciPostupno);
			}
		}
		
		public function ZarotirajSeZa180(e:Event):void
		{
			if (PocetnaRotacija == 360)  // ako se ova funkcija prvi put pokreće (inače se pokreće svaki frame), početna rotacija će biti 360. U tom prvom pokretanju postavljamo početnu rotaciju te Zoomiramo ploču na faktor zumiranja ploče
			{
				PocetnaRotacija = this.rotation;
				if (! PlocaZoomirana)
				{
					// čemu će nam ovaj if statement? Ploča se smije zoomirati samo kada se prvi puta rotiramo za 180 (prije nego krenemo unatrag). Kada se rotiramo drugi puta (kada smo krečući se unatrag došli na odredište), tada će ploča već biti zoomirana. Ponovno zoomiranje je neće još više zoomirati (jer će je skalirati 3 puta, na što je već i skalirana), ali će poremetiti centar zoom-a, tako da ju kada stigne na odredište nećemo zoomirati
					ZoomirajPlocu(FAKTOR_ZOOMIRANJA_PLOCE); 
					PlocaZoomirana = true;
				}
				else
					PlocaZoomirana = false;
			}
				
			var zavrsnaRotacija:int;
			switch (PocetnaRotacija)
			{
				case 0: zavrsnaRotacija = 180; break;
				case 90: zavrsnaRotacija = -90; break;
				case 180:
				case -180: zavrsnaRotacija = 0; break;
				case -90: zavrsnaRotacija = 90; break;
			}
			
			if (this.rotation != zavrsnaRotacija)
			{
				this.rotation += 15;
			}
			else
			{
				this.removeEventListener(Event.ENTER_FRAME, ZarotirajSeZa180);
				PocetnaRotacija = 360;
				this.dispatchEvent(new Event("Rotacija za 180 gotova"));
			}
		}
		
		private function ZoomirajPlocu(faktorZoomiranja:Number)
		{			
			Monopoly.KontejnerIgre.scaleX = faktorZoomiranja;
			Monopoly.KontejnerIgre.scaleY = faktorZoomiranja;
			
			/*
			 * ove dvije linije su ključne! Kontejner igre ima registracijsku točku postavljenu na (0,0). 
			 * Kada ploču zumiramo 3 puta, koordinate kontejnera igre ćemo postaviti na figuricu igrača koji je na potezu
			 * uvećane za faktor zumiranja ploče. Zbog toga što je registracijska točka bila (0,0), sada će se i 
			 * figurica igrača nalaziti na (0,0) na ekranu. Ako je želimo na sredini, oduzet ćemo od
			 * x i y koordinata kontejnera još polovicu koordinata stage-a, tj. 320 i 240 i dobit ćemo figuricu na sredini
			 * zumirane ploče
			 */
			Monopoly.KontejnerIgre.x -= this.x * faktorZoomiranja - 320;
			Monopoly.KontejnerIgre.y -= this.y * faktorZoomiranja - 240;
		}
		
		private function PomiciPlocu(e:Event):void
		{
			var sadrzajPloce = e.currentTarget as Sprite;	// kontejner igre
			var tajmer:Timer = new Timer(1000, 1);
			
			if (PreostaloPolja != 0) // tj. ako se figurica još miče
			{
				// pomicat će se i ploča sa svojim sadržajem kojeg ćemo svaki puta najprije resetirati
				sadrzajPloce.x = 0;
				sadrzajPloce.y = 0;
				sadrzajPloce.x -= this.x * FAKTOR_ZOOMIRANJA_PLOCE - 320;
				sadrzajPloce.y -= this.y * FAKTOR_ZOOMIRANJA_PLOCE - 240;
			}
			else
			{
				// ako je figurica stala s pomicanjem, pričekat ćemo neko vrijeme da igrač vidi gdje je stala i odzumirat ćemo ploču
				sadrzajPloce.removeEventListener(Event.ENTER_FRAME, PomiciPlocu);
				
				tajmer.start();
				tajmer.addEventListener(TimerEvent.TIMER, VratiPlocuNaStaro); 
				function VratiPlocuNaStaro (e:TimerEvent):void
				{
					tajmer.removeEventListener(TimerEvent.TIMER, VratiPlocuNaStaro); 
					tajmer.stop();
					ZoomirajPlocu(1);
					sadrzajPloce.x = 0;
					sadrzajPloce.y = 0;
					
					CentrirajFiguricuNaPolju();
					
					if (! igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
						Monopoly.KlikanjePoPlociOnOff(true);
					
					Polje.Polja[Pozicija].IgracStaoNaPolje();
				}
			}
		}
		
		private function DodijeliFiguriciIme():void
		{
			var naziviFigurica:Array = new Array("Šešir", "Pas", "Ratni brod", "Automobil", "Kotač", "Glačalo", "Naprstak", "Čizma", "Konjanik", "Kolica");
			
			// dodijeljujemo figurici naziv. On će se koristiti kad se bude korisniku prikazivala poruka tko prvi igra
			// Od vrijednosti broja figurice oduzimamo jedan, zato jer se broj figurice u originalu odnosi na objekt "figuricaOdabir_mc" koji ima jedan više frame od "figurica_mc" za kojeg nam je i potreban broj figurice
			this.ImeFigurice = naziviFigurica[BrojFigurice - 1];
		}
		
		private function CentrirajFiguricuNaPolju():void 
		{
			if (Pozicija % 10 != 0)	// ako nismo na nekom od rubnih polja
			{
				if (StranaPolja == GORE || StranaPolja == DOLJE)
				{
					x = Polje.Polja[Pozicija].VratiSredinuPolja().x;
					y = (StranaPolja == DOLJE) ?  (480 - OdmakOdRuba) : OdmakOdRuba;
					BijeliPrsten.x = x;
					BijeliPrsten.y = y;
				} else
				{
					x = (StranaPolja == LIJEVO) ? OdmakOdRuba : (480 - OdmakOdRuba);
					y = Polje.Polja[Pozicija].VratiSredinuPolja().y;
					BijeliPrsten.x = x;
					BijeliPrsten.y = y;
				}
			} else  // a ako jesmo
			{
				switch (Math.abs(Pozicija / 10))
				{
					case 0:
						x = RUBNA_POZICIJA;
						y = 480 - OdmakOdRuba;
						BijeliPrsten.x = x;
						BijeliPrsten.y = y;
						break;
					case 1:
						x = OdmakOdRuba;
						y = RUBNA_POZICIJA;
						BijeliPrsten.x = x;
						BijeliPrsten.y = y;
						break;
					case 2:
						x = 480 - RUBNA_POZICIJA;
						y = OdmakOdRuba;
						BijeliPrsten.x = x;
						BijeliPrsten.y = y;
						break;
					case 3:
						x = 480 - OdmakOdRuba;
						y = 480 - RUBNA_POZICIJA;
						BijeliPrsten.x = x;
						BijeliPrsten.y = y;
						break;
				}
			}
		}
	}
}
