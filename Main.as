package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.display.StageQuality;
	
	public class Main extends MovieClip {
		private var Kontejner:Sprite = new Sprite();
		private var BrojeviFiguricaIgraca:Array;
		private var FiguriceIgraca:Vector.<figuricaOdabir_mc>;
		private var TipoviIgraca:Vector.<tipIgraca_mc>;
		public var Glazba:Boolean = true;
		private var NovciIzAnimacije:Vector.<novci_mc>;
		private var Novci_kontejner:Sprite = new Sprite();
		private var IdPadajucegNovca:uint = 0;
		private var BrojFramea:uint;
		private var IgraUTijeku:Igra;
		private var KanalGlazbe:SoundChannel;
		
		public function Main() {
			stage.quality = "8X8";  // ova kvaliteta nam je potrebna da prilikom resize-anja ne dobijemo oštre rubove i sl. Još bolja je "16X16". Postoji i "16x16LINEAR" (malo lošija), ali nam one nisu potrebne
			Novci_kontejner.name = "ne pomjeraj";
			IdiUGlavniIzbornik();
		}
		
		private function IdiUGlavniIzbornik(e:MouseEvent = null):void
		{			
			addChild(Kontejner);
			IsprazniKontejner(Kontejner);
			ResetirajVrijednostiZaPadajuciNovac();
			gotoAndStop(1);
			
			Kontejner.addChild(LogoGlavniIzbornik);
			Kontejner.addChild(Novci_kontejner);
			Kontejner.addChild(NovaIgra_gumb);
			Kontejner.addChild(Glazba_gumb);
			Kontejner.addChild(Zvucnik_gumb);
			
			NovaIgra_gumb.buttonMode = true;
			Zvucnik_gumb.buttonMode = true;
			if (Glazba)
				Zvucnik_gumb.gotoAndStop(1);
			else
				Zvucnik_gumb.gotoAndStop(2);
			
			NovaIgra_gumb.addEventListener(MouseEvent.CLICK, IdiNaOdabirIgraca);
			Zvucnik_gumb.addEventListener(MouseEvent.CLICK, GlazbaOnOff);
			
			// puštamo glazbu (puštat će se 1000 puta u petlji)
			if (KanalGlazbe == null)
				KanalGlazbe = (new pozadinskaPjesma_snd()).play(0, 1000);
			
			// Svakim novim frame-om poziva se funkcija koja pomiče sadržaj (bilo kojeg) kontejnera za 15px lijevo
			Kontejner.addEventListener(Event.ENTER_FRAME, PomiciFrameLijevo);
		}
		
		private function IdiNaOdabirIgraca(e:MouseEvent):void
		{
			FiguriceIgraca = new Vector.<figuricaOdabir_mc>();
			TipoviIgraca = new Vector.<tipIgraca_mc>();
			BrojeviFiguricaIgraca = new Array(-1,-1,-1,-1);

			IsprazniKontejner(Kontejner);
			ResetirajVrijednostiZaPadajuciNovac();
			gotoAndStop(2);
			addChild(Kontejner);
			
			/* 
			 * Inicijaliziranje svih objekata na glavnom frame-u broj 2 
			 * (odabir igrača koji će igrati) 
			 * i stavljanje svakog od njih u kontejner
			 */
			
			Kontejner.addChild(LogoOdabirIgraca);
			Kontejner.addChild(Novci_kontejner);
			
			// Postavljanje početnih figurica igrača. Ove 4 varijable (FiguricaIgracaX) su instancirane u Adobe Flash-u na drugom frame-u
			FiguriceIgraca.push(FiguricaIgraca1);
			FiguriceIgraca.push(FiguricaIgraca2);
			FiguriceIgraca.push(FiguricaIgraca3);
			FiguriceIgraca.push(FiguricaIgraca4);
			var bojaPrveFigurice:ColorTransform = new ColorTransform; 
			bojaPrveFigurice.color = 0x0000ff;
			var bojaDrugeFigurice:ColorTransform = new ColorTransform; 
			bojaDrugeFigurice.color = 0xffff00;
			FiguricaIgraca1.Pozadina.transform.colorTransform = bojaPrveFigurice;	 // prvom igraču dajemo plavu boju
			FiguricaIgraca2.Pozadina.transform.colorTransform = bojaDrugeFigurice;  // drugom žutu
			
			for (var i:uint = 0; i < FiguriceIgraca.length; i++)
			{
				with (FiguriceIgraca[i])
				{
					Kontejner.addChild(FiguriceIgraca[i]);
					gotoAndStop(1);
					buttonMode = true;
					addEventListener(MouseEvent.CLICK, PromijeniFiguricu);
				}
			}
			
			FiguricaIgraca1.gotoAndStop(GenerirajBrojFigurice(FiguricaIgraca1.currentFrame, 0));
			FiguricaIgraca2.gotoAndStop(GenerirajBrojFigurice(FiguricaIgraca2.currentFrame, 1));
			
			// Postavljanje početnih tipova igrača (tekstovi). Ove 4 varijable (TipIgracaX) su instancirane u Adobe Flash-u na drugom frame-u
			TipoviIgraca.push(TipIgraca1);
			TipoviIgraca.push(TipIgraca2);
			TipoviIgraca.push(TipIgraca3);
			TipoviIgraca.push(TipIgraca4);
			
			for (i = 0; i < TipoviIgraca.length; i++)
			{
				with (TipoviIgraca[i])
				{
					Kontejner.addChild(TipoviIgraca[i]);
					gotoAndStop(i % 2 + 1);
					buttonMode = true;
					mouseChildren = false;
					Tekst.text = "(odaberite)";
					addEventListener(MouseEvent.CLICK, PromijeniTipIgraca);
				}
			}
			
			TipIgraca1.Tekst.text = "Osoba";
			TipIgraca2.Tekst.text = "AI";
			
			
			Kontejner.addChild(Otkazi_gumb);
			Otkazi_gumb.gotoAndStop(2);
			Otkazi_gumb.buttonMode = true;
			Otkazi_gumb.addEventListener(MouseEvent.CLICK, IdiUGlavniIzbornik);
			
			Kontejner.addChild(Prihvati_gumb);
			Prihvati_gumb.gotoAndStop(1);
			Prihvati_gumb.buttonMode = true;
			Prihvati_gumb.addEventListener(MouseEvent.CLICK, Igraj);
			
			// Svakim novim frame-om poziva se funkcija koja pomiče sadržaj (bilo kojeg) kontejnera za 15px lijevo
			Kontejner.addEventListener(Event.ENTER_FRAME, PomiciFrameLijevo);
		}
		
		private function IsprazniKontejner(kontejner:Sprite):void
		{
			while (kontejner.numChildren > 0)
				kontejner.removeChildAt(0);
		}
		
		private function GenerirajBrojFigurice(trenutnaFigurica:uint, mjestoUPolju:uint):uint
		{
			var brojFigurice:uint;	// broj Frame-a figurice
			
			// generiramo novi broj figurice i umećemo ga u polje
			do
			{
				brojFigurice = Math.floor(Math.random() * 10) + 2;		
			} while (BrojeviFiguricaIgraca.indexOf(brojFigurice) != -1);
			BrojeviFiguricaIgraca.splice(mjestoUPolju, 1, brojFigurice);
			return brojFigurice;
		}
		
		private function PomiciFrameLijevo(e:Event):void
		{
			const LOKACIJA_REFERENTNOG_OBJEKTA = 0;
			const POMAK:uint = 40;
			const NAJLIJEVIJA_POZICIJA = 180;
			var frame:Sprite = e.currentTarget as Sprite;
			
			if (frame.getChildAt(LOKACIJA_REFERENTNOG_OBJEKTA).x > NAJLIJEVIJA_POZICIJA)
			{
				for (var i:uint = 0; i < frame.numChildren; i++)
					if (frame.getChildAt(i).name != "ne pomjeraj")
						frame.getChildAt(i).x -= POMAK;
			}
			else
			{
				frame.removeEventListener(Event.ENTER_FRAME, PomiciFrameLijevo);
				addEventListener(Event.ENTER_FRAME, KisaNovca);
			}
		}
		
		private function PromijeniTipIgraca(e:MouseEvent):void
		{
			var igrac = e.currentTarget as MovieClip;
			var tekstoviTipaIgraca:Array = [ "Osoba", "AI", "(odaberite)" ];
			var tekst:String = igrac.Tekst.text;
			var pozicijaTesktaUPolju:uint = tekstoviTipaIgraca.indexOf(tekst);
			
			igrac.Tekst.text = tekstoviTipaIgraca[(pozicijaTesktaUPolju + 1) % 3];
			ProvjeriFigurice();
			DodajUkloniMogucnostIgranja();
		}
		
		private function ProvjeriFigurice():void
		{
			const MAX_BROJ_FIGURICA:uint = 4;
			for (var i:uint = 0; i < MAX_BROJ_FIGURICA; i++)
			{
				if (TipoviIgraca[i].Tekst.text == "(odaberite)")
				{
					// uklanjamo broj figurice iz polja
					BrojeviFiguricaIgraca.splice(i, 1, -1);
					// uklanjamo figuricu s prikaza
					FiguriceIgraca[i].gotoAndStop(1);
					// mijenjamo boju figurice natrag u sivu
					ObojiPozadinuFigurice(FiguriceIgraca[i], true);
				}
					
				if (TipoviIgraca[i].Tekst.text != "(odaberite)" && FiguriceIgraca[i].currentFrame == 1)
				{
					FiguriceIgraca[i].gotoAndStop(GenerirajBrojFigurice(FiguriceIgraca[i].currentFrame, i));
					ObojiPozadinuFigurice(FiguriceIgraca[i]);
				}
			}
		}
		
		private function PromijeniFiguricu(e:MouseEvent):void
		{
			var figurica:figuricaOdabir_mc = e.currentTarget as figuricaOdabir_mc;
			var indeksTrenutneFigurice:uint = figurica.currentFrame;
			var indeksSljedeceFigurice:uint = indeksTrenutneFigurice;
			
			// ako smo na praznoj figurici, i mijenjamo je, moramo promijeniti i boju pozadine figurice
			if (indeksTrenutneFigurice == 1)
				ObojiPozadinuFigurice(figurica);
			
			do
			{
				indeksSljedeceFigurice++;
				if (indeksSljedeceFigurice == 12)
					indeksSljedeceFigurice = 2;
			} while (BrojeviFiguricaIgraca.indexOf(indeksSljedeceFigurice) != -1);
			BrojeviFiguricaIgraca.splice(FiguriceIgraca.indexOf(figurica), 1, indeksSljedeceFigurice);
			figurica.gotoAndStop(indeksSljedeceFigurice);
			
			ProvjeriIgrace();
		}
		
		
		private function ProvjeriIgrace():void
		{
			const MAX_BROJ_IGRACA:uint = 4;
			for (var i:uint = 0; i < MAX_BROJ_IGRACA; i++)
			{
				if (TipoviIgraca[i].Tekst.text == "(odaberite)" && FiguriceIgraca[i].currentFrame != 1)
				{
					TipoviIgraca[i].Tekst.text = "Osoba";
					DodajUkloniMogucnostIgranja();
				}
			}
		}
		
		private function GlazbaOnOff(e:MouseEvent):void
		{
			const ON:uint = 1;
			const OFF:uint = 2;
			var zvucnik:MovieClip = e.currentTarget as MovieClip;
			
			if (Glazba)
			{
				Glazba = false;
				zvucnik.gotoAndStop(OFF);
			} else
			{
				Glazba = true;
				zvucnik.gotoAndStop(ON);
			}
			
			addEventListener(Event.ENTER_FRAME, PojacavajSmanjujGlazbuPostupno);
		}
		
		private function Igraj(e:MouseEvent):void
		{
			ResetirajVrijednostiZaPadajuciNovac();
			IsprazniKontejner(Kontejner);
			Prihvati_gumb.removeEventListener(MouseEvent.CLICK, Igraj);
			removeEventListener(Event.ENTER_FRAME, KisaNovca);
			/* da objektu Igra ne šaljemo grafičke objekte TipIgrača, 
			 * poslat ćemo mu samo ono što mu je bitno, a to su informacije TKO igra (osoba ili AI).
			 * Naravno, pritom se neće poslati i informacije tipa "(odaberite)"
			 */
			var tipoviIgraca:Array = new Array();
			var figuriceIgraca:Vector.<figuricaOdabir_mc> = new Vector.<figuricaOdabir_mc>();
			var brojeviFiguricaIgraca:Array = new Array();
			
			// filtriramo Tipove igrača
			for (var i:uint = 0; i < TipoviIgraca.length; i++)
				if (TipoviIgraca[i].Tekst.text != "(odaberite)")
					tipoviIgraca.push(TipoviIgraca[i].Tekst.text);
					
			
			// filtriramo figurice igrača za prikaz i uklanjamo event listenere s njih
			for (i = 0; i < FiguriceIgraca.length; i++)
			{
				if (FiguriceIgraca[i].Pozadina.transform.colorTransform.color != 0x555555)	// želimo samo one figurice koje su odabrane (tj. ne i sive!!)
					figuriceIgraca.push(FiguriceIgraca[i]);
				FiguriceIgraca[i].removeEventListener(MouseEvent.CLICK, PromijeniFiguricu);
			}
			
			// filtriramo brojeve figurica igrača
			for (i = 0; i < BrojeviFiguricaIgraca.length; i++)
				if (BrojeviFiguricaIgraca[i] != -1)
					brojeviFiguricaIgraca.push(BrojeviFiguricaIgraca[i]);
				
			// instanciramo novi objekt same igre i šaljemo mu informacije o figuricama koje treba postaviti i informacije o tome koje figurice predstavljaju čovjeka ("Osoba"), a koje AI
			IgraUTijeku = new Igra(brojeviFiguricaIgraca, figuriceIgraca, tipoviIgraca);
			Kontejner.addChild(IgraUTijeku);
			gotoAndStop(3);
		}
		
		private function KisaNovca(e:Event):void
		{
			const DA_SE_NE_VIDI = -50;
			const IZVAN_EKRANA = 500;
			var novac:novci_mc = new novci_mc();
			novac.gotoAndStop(Math.floor(Math.random() * 7) + 1);
			var novciKojiSuPali:Array = new Array();
			
			// u svakom petom frameu stvaramo novu novčanicu i dodjeljujemo joj brzinu pada
			BrojFramea = (BrojFramea + 1) % 15;  // svaki 15 frame spuštamo novu novčanicu. Znači 2 novčanice u sekundi (za 30 fps)
			if (BrojFramea == 0)
			{
				novac.x = Math.random() * 640;
				novac.y = DA_SE_NE_VIDI;
				novac.rotation = Math.random() * 360;
				do
				{
					// smjer rotacije može biti -1 i 1. Označava hoće li se novac rotirati lijevo ili desno
					novac.smjerRotacije = Math.floor(Math.random() * 3) - 1;	// generiramo -1, 0 ili 1
				} while (novac.smjerRotacije == 0);	// sve dok je smjer rotacije jednak nuli
				novac.brzina = Math.floor(Math.random() * 2) + 2;	// između 1 i 5 pixela po sekundi
				novac.name = IdPadajucegNovca.toString();	// dodjeljujemo mu ime koje odgovara poziciji u polju
				IdPadajucegNovca++;
				Novci_kontejner.addChild(novac);
				NovciIzAnimacije.push(novac);
			}
			
			// pomičemo svaki novac prema dolje konstantnom njegovom brzinom i bilježimo novce koji su pali
			for (var i:uint = 0; i < NovciIzAnimacije.length; i++)
			{
				NovciIzAnimacije[i].y += NovciIzAnimacije[i].brzina;
				// rotiramo novac u smjeru rotacije
				NovciIzAnimacije[i].rotation += NovciIzAnimacije[i].smjerRotacije;
				
				if (NovciIzAnimacije[i].y > IZVAN_EKRANA)
				{
					novciKojiSuPali.push(i);
				}
			}
			
			//brišemo novce koji su izašli (pali), iz polja i sa stage-a
			for (i = 0; i < novciKojiSuPali.length; i++)
			{
				Novci_kontejner.removeChild(Novci_kontejner.getChildByName(NovciIzAnimacije[novciKojiSuPali[i]].name));
				NovciIzAnimacije.splice(novciKojiSuPali[i], 1);
			}
		}
		
		private function ResetirajVrijednostiZaPadajuciNovac():void
		{
			IsprazniKontejner(Novci_kontejner);
			NovciIzAnimacije = new Vector.<novci_mc>();
			IdPadajucegNovca = 0;			
		}
		
		private function ProvjeriValjanostOdabira():Boolean
		{
			// ako je odabran jedan jedini igrač, odabir nije valjan
			var brojIgraca:uint = 0;
			for (var i:uint = 0; i < BrojeviFiguricaIgraca.length; i++)
				if (BrojeviFiguricaIgraca[i] != -1)
					brojIgraca++;
					
			if (brojIgraca < 2)
				return false;
			
			// ako postoji barem jedan odabrani igrač da je "osoba", odabir je valjan.
			for (i = 0; i < TipoviIgraca.length; i++)
				if (TipoviIgraca[i].Tekst.text == "Osoba")
					return true;
			
			// u svakom drugom slučaju, odabir nije valjan
			return false;
			//return true;
		}
		
		private function DodajUkloniMogucnostIgranja():void
		{
			if (ProvjeriValjanostOdabira())
				with (Prihvati_gumb)
				{
					if (! hasEventListener(MouseEvent.CLICK))
						addEventListener(MouseEvent.CLICK, Igraj);
					alpha = 1;
					buttonMode = true;
				}
			else
				with (Prihvati_gumb)
				{
					if (hasEventListener(MouseEvent.CLICK))
						removeEventListener(MouseEvent.CLICK, Igraj);
					alpha = 0.5;
					buttonMode = false;
				}
		}
		
		private function ObojiPozadinuFigurice(figurica:figuricaOdabir_mc, siva:Boolean=false):void
		{
			const PRVA_FIGURICA:uint = 0, DRUGA_FIGURICA:uint = 1, TRECA_FIGURICA:uint = 2, CETVRTA_FIGURICA:uint = 3;
			var indeksUPoljuFigurica:uint;
			var boja:uint;
			
			// najprije pronalazimo indeks figurice u polju (jer svaka figurica u polju ima različitu boju)
			for (var i:uint = 0; i < FiguriceIgraca.length; i++)
				if (FiguriceIgraca[i] == figurica)
					indeksUPoljuFigurica = i;
					
			// potom postavljamo boju figurice u varijablu boja (s obzirom na nađeni indeks)
			switch (indeksUPoljuFigurica)
			{
				case PRVA_FIGURICA: boja = 0x0000ff; break;  // plava boja
				case DRUGA_FIGURICA: boja = 0xffff00; break;  // žuta boja
				case TRECA_FIGURICA: boja = 0xff00ff; break;  // rozna boja
				case CETVRTA_FIGURICA: boja = 0xdd0000; break;  // crvena boja
			}
			
			
			// napokon mijenjamo boju figurice
			var promjenaBoje:ColorTransform = new ColorTransform();
				// ako je bio proslijeđen argument "siva", figuricu bojamo u sivo. U suprotnom, bojamo ju u boju određenu iznad
			if (siva)
				promjenaBoje.color = 0x555555;
			else
				promjenaBoje.color = boja;
				
			figurica.Pozadina.transform.colorTransform = promjenaBoje;
		}
		
		private function PojacavajSmanjujGlazbuPostupno(e:Event)
		{
			var uvjetSmanjivanjaPojacavanja:Boolean;
			var smjerPojacavanja:int;
			if (Glazba)
			{
				uvjetSmanjivanjaPojacavanja = KanalGlazbe.soundTransform.volume < 1;
				smjerPojacavanja = 1;
			}
			else
			{
				uvjetSmanjivanjaPojacavanja = KanalGlazbe.soundTransform.volume > 0;
				smjerPojacavanja = -1;
			}
			
			var novaGlasnoca:SoundTransform = new SoundTransform(KanalGlazbe.soundTransform.volume + 0.05 * smjerPojacavanja);
			
			if (uvjetSmanjivanjaPojacavanja)
				KanalGlazbe.soundTransform = novaGlasnoca;
			else
				removeEventListener(Event.ENTER_FRAME, PojacavajSmanjujGlazbuPostupno);
		}
	}
}
