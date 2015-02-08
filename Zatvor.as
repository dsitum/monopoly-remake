package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class Zatvor extends Sprite {	// proširujemo ga sa Sprite jer nam treba kako bi mogli koristiti metodu "parent" i tako pristupiti igraču
		public var PreostaliBrojBacanja:uint = 3;
		private var Monopoly:Igra;
		private var Igrac:igrac_mc;
		
		public function Zatvor() {
			// čim se instancira objekt tipa zatvor, pomičemo se u zatvor
			this.addEventListener(Event.ADDED_TO_STAGE, IdiUZatvor);
		}
		
		private function IdiUZatvor(e:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, IdiUZatvor);
			const INDEKS_POLJA_ZATVORA:uint = 10;  // indeks polja na koje se trebamo pomaknuti (ono polje s rešetkama)
			Igrac = this.parent as igrac_mc;
			Monopoly = Igrac.parent.parent.parent as Igra;
			Igrac.IsteKockice = new Vector.<Boolean>();  // praznimo polje informacija o istim kockicama u zadnja tri poteza
			
			// puštamo zvuk sirene
			var zvukSirene:policija_snd = new policija_snd();
			zvukSirene.play();
			Igrac.IdiNaPolje(INDEKS_POLJA_ZATVORA);
			
			// Dodajemo event listener za izlazak iz zatvora
			Igrac.addEventListener("Kocke su stale", IzadjiIzZatvoraAkoSuIsteKocke);
			// dodajemo event listener na polje "U zatvoru"
			Igrac.addEventListener("U zatvoru", ZavrsiBacanje); 
			function ZavrsiBacanje (e:Event)
			{
				Igrac.removeEventListener("U zatvoru", ZavrsiBacanje);
				Monopoly.ZavrsiBacanje();
			}
		}
		
		private function IzadjiIzZatvoraAkoSuIsteKocke(e:Event):void
		{
			const BACANJE_GOTOVO:uint = 1;
			// ako su kocke iste, izlazimo iz zatvora
			if (kocka_mc.Kocke[0].currentFrame == kocka_mc.Kocke[1].currentFrame)
			{
				Igrac.removeEventListener("Kocke su stale", IzadjiIzZatvoraAkoSuIsteKocke);
				// praznimo polje posljednjih bacanja
				Igrac.IsteKockice = new Vector.<Boolean>();
				// skrivamo kontrole za izlaz iz zatvora
				Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].visible = false;
				
				// pomičemo se za dobiveni broj kockica
				Igrac.Figurica.PomakniFiguricu(kocka_mc.Kocke[0].currentFrame + kocka_mc.Kocke[1].currentFrame);
				
				this.dispatchEvent(new Event("Izadji iz zatvora" + igrac_mc.IgracNaPotezu));
			} else
			{	// a ako kocke nisu iste, a preostali broj bacanja je 0
				if (PreostaliBrojBacanja == BACANJE_GOTOVO)  // zašto ako je preostali broj bacanja jednak 1? Zato jer se preostali broj bacanja smanjuje u klasi kocka_mc. Kada se tri puta bace kocke (a budući da event ima prednost nad slijedom), taj broj će u ovom trenutku biti 1
				{
					if (Igrac.AIIgrac)  // ukoliko se radi o AI igraču, tada će on platiti za izlaz
						KliknutoNaNovac();
					else  // ukoliko se radi o čovjeku, omogućavamo mu plaćanje
					{
						Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].NovacZaIzlaz.alpha = 1;
						Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].NovacZaIzlaz.addEventListener(MouseEvent.CLICK, KliknutoNaNovac);
					}
				}
			}
		}
		
		public function KliknutoNaNovac(e:MouseEvent=null):void
		{
			if (e != null)
			{
				var upravljackeIkoneZaIzlaz:upravljackeIkone_mc = e.currentTarget.parent as upravljackeIkone_mc;
				// uklanjamo sve listenere
				upravljackeIkoneZaIzlaz.NovacZaIzlaz.removeEventListener(MouseEvent.CLICK, KliknutoNaNovac);
				upravljackeIkoneZaIzlaz.KarticaZaIzlaz.removeEventListener(MouseEvent.CLICK, KliknutoNaKarticu);
				upravljackeIkoneZaIzlaz.visible = false;
			}
			Igrac.removeEventListener("Kocke su stale", IzadjiIzZatvoraAkoSuIsteKocke);
			PlacenoZaIzlazIzZatvora();
		}
		
		private function PlacenoZaIzlazIzZatvora():void
		{
			// praznimo polje posljednjih bacanja
			Igrac.IsteKockice = new Vector.<Boolean>();
			// uzimamo igraču 1000 kuna
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = -1;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= 1000;
			this.dispatchEvent(new Event("Izadji iz zatvora" + igrac_mc.IgracNaPotezu));
			// i ako je plaćeno nakon što je bačeno treći puta, pomičemo figuricu igrača za dobiveni broj na kockama
			if (PreostaliBrojBacanja == 0)
				Igrac.Figurica.PomakniFiguricu(kocka_mc.Kocke[0].currentFrame + kocka_mc.Kocke[1].currentFrame);
		}
		
		public function KliknutoNaKarticu(e:MouseEvent=null):void
		{
			if (e != null)
			{
				var upravljackeIkoneZaIzlaz:upravljackeIkone_mc = e.currentTarget.parent as upravljackeIkone_mc;
				// uklanjamo sve listenere
				upravljackeIkoneZaIzlaz.NovacZaIzlaz.removeEventListener(MouseEvent.CLICK, KliknutoNaNovac);
				upravljackeIkoneZaIzlaz.KarticaZaIzlaz.removeEventListener(MouseEvent.CLICK, KliknutoNaKarticu);
				upravljackeIkoneZaIzlaz.visible = false;
			}
			Igrac.removeEventListener("Kocke su stale", IzadjiIzZatvoraAkoSuIsteKocke);
			UpotrjebljenaKarticaIzadjiIzZatvora();
		}
		
		private function UpotrjebljenaKarticaIzadjiIzZatvora():void
		{
			// praznimo polje posljednjih bacanja
			Igrac.IsteKockice = new Vector.<Boolean>();
			// uklanjamo igračevu karticu za izlaz iz zatvora
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].KarticeIzadjiIzZatvora.pop();
			
			// stvaramo tu istu karticu sreće kako bi je mogli vratiti u špil
			var kartica:KarticaSrece = new KarticaSrece(0, "Ova karta može se sačuvati dok\nse ne upotrijebi ili se može prodati.", true);
			if (Monopoly.PoljaSrece.TekstoviKarticaDrzavneBlagajne.indexOf(kartica) == -1)  // ako u karticama državne blagajne ova kartica ne postoji (nema je), onda je ondje vraćamo. U suprotnom, vraćamo je u kartice šanse
				Monopoly.PoljaSrece.TekstoviKarticaDrzavneBlagajne.unshift(kartica);
			else
				Monopoly.PoljaSrece.TekstoviKarticaSanse.unshift(kartica);
				
			// okidamo event za izlazak iz zatvora
			this.dispatchEvent(new Event("Izadji iz zatvora" + igrac_mc.IgracNaPotezu));
		}
	}
}
