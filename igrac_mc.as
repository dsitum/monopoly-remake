package  {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class igrac_mc extends MovieClip {
		protected static var Monopoly:Igra;
		public static var Igraci:Array = new Array();
		private static var _IgracNaPotezu:uint = 0;
		public var AIIgrac:Boolean;
		protected var _Novac:int = 30000;
		public var Boja:uint;
		public var Figurica:figurica_mc;
		public var IsteKockice:Vector.<Boolean> = new Vector.<Boolean>();  // imat će stanja broja kockica u 3 posljednja poteza: jesu li bili isti brojevi na njima ili ne
		public var UZatvoru:Zatvor;
		public var KarticeIzadjiIzZatvora:Vector.<karticaSrece_mc> = new Vector.<karticaSrece_mc>();
		protected var UMinusu:Boolean = false;
		private var IndirektnoUMinusu:Boolean = false;  // ova varijabla biti će true kada igrač ode u minus a nije na potezu. Zašto nam ona treba? Zato da kad on dođe na potez, i izvuče se iz minusa, da može bacati kockice (a ne samo stisnuti endturn)
		private var _Bankrotirao:Boolean = false;
		public var ZadnjePlacanje:int;  // svaki puta kada igrač plati nešto, u ovu će se varijablu upisati indeks igrača kojemu je platio (ili -1 ako se radi o banci). Ako igrač bankrotira, na ovaj ćemo način znati tko ga je doveo do bankrota. To nam je jako bitno
		
		public function igrac_mc(figuica:figurica_mc) {
			Figurica = figuica;
			this.addChild(Figurica);
			// dodajemo event listener za iste kockice
			this.addEventListener("Kocke su stale", IstiBrojeviNaKockama);
			this.addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			Monopoly = this.parent.parent.parent as Igra;
			Boja = PronadjiBojuIgraca();
		}
		
		public function get Novac():int
		{
			return _Novac;
		}
		
		public function set Novac(novac:int):void
		{
			// radimo ovaj setter, kako bi se, svaki puta kada se promijeni vrijednost novca igrača, promijenila i vrijednost prikaza
			var stariNovac:int = _Novac;
			_Novac = novac;
			
			// pronalazimo indeks igrača kojem se oduzima novac
			var indeksIgraca:uint;
			for (var i:uint = 0; i < Igraci.length; i++)
				if (Igraci[i] == this)
					indeksIgraca = i;
			
			Monopoly.PrikaziNovca[indeksIgraca].Novac.text = novac.toString() + "Kn";
			if (Igraci[IgracNaPotezu] == this)  // puštamo zvuk samo ako se radi o novcu igrača koji je na potezu
			{
				if (novac != stariNovac)  // ova provjera nam je potrebna jer ponekad će se novac smanjiti za 0kn, a tada ne želimo da se pušta zvuk (npr kad se plaća po kući i po hotelu, a igrač nema ni kuće ni hotela)
				{
					if (novac > stariNovac)
						(new novacplus_snd()).play();  // reproduciramo zvuk novca
					else
						(new novacminus_snd()).play();
				}
			}
				
			if (novac <= 0 && stariNovac > 0)  // ako igračev novac padne na nulu ili ispod
			{
				UMinusu = true;  // postavljamo ga u stanje "U minusu"
				if (Igraci[IgracNaPotezu] == this)  // ako se radi o igraču koji je na potezu ...
				{
					if (this.AIIgrac)  // ... i ako je taj igrač AI, pustit ćemo mu da odluči o minusu
						(this as AI).OdluciOMinusu(_Novac, true, stariNovac);
					else  // .. i ako taj igrač nije AI, i ako može vratiti minus, prikazat ćemo dijalog s informacijom. U suprotnom ćemo prikazati dijalog s bankrotom
						PrikaziDijalogONedostatkuNovca(stariNovac);	// prikazujemo dijalog o nedostatku novca / bankrotu. Proslijeđujemo mu argument "stari novac" jer ako je ovaj igrač bankrotirao i ako ga je drugi igrač doveo do bankrota, njemu će se morati dati sav novac koji je igrač imao prije bankrota (tj. stari novac)
				} else  // a ako je u minus otišao igrač koji nije na potezu, znači da je indirektno otišao u minus, te mu dodjeljujemo to stanje
				{
					this.IndirektnoUMinusu = true;
				}
			}
			else if (novac > 0 && stariNovac <= 0) // ako igračev novac poraste iznad nule
			{
				UMinusu = false;  // igrača postavljamo da nije više u minusu
				if (Igraci[IgracNaPotezu] == this)  // ako se radi o igraču koji je na potezu ...
				{
					if (this.AIIgrac)  // ... i ako je taj igrač AI ...
					{
						if (IndirektnoUMinusu)  // .. a indirektno je bio u minusu, bacamo kocke
						{
							IndirektnoUMinusu = false;
							Monopoly.BaciKockice();
						} else	// ... a ako nije indirektno bio u minusu, završavamo potez
						{
							Monopoly.ZavrsiPotez();
						}
					}
					else // ... i ako je taj igrač nije AI, omogućujemo mu završavanje poteza
					{
						if (IndirektnoUMinusu)  // ako je igrač na potezu bio indirektno postavlje u minus, omogućujemo mu gumb za bacanje kockica
						{
							Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].addEventListener(MouseEvent.CLICK, Monopoly.BaciKockice);
							Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].alpha = 1;
							IndirektnoUMinusu = false;
						} else  // a ako nije bio indiretkno postavljen u minus, omogućujemo mu gumb za završavanje poteza
						{
							Monopoly.SakrijPokaziGumbZaKrajPoteza(true);
						}
					}
				} else
				{
					this.IndirektnoUMinusu = false;
				}
			}
		}
		
		public static function get IgracNaPotezu():uint
		{
			return _IgracNaPotezu;
		}
		
		public static function set IgracNaPotezu(igracNaPotezu:uint):void
		{
			// Prikazanu figuricu također mijenjamo da odgovara novom igraču: staru figuricu postavljamo kao nevidljivu, a novu kao vidiljivu
			Monopoly.FiguriceZaPrikaz[_IgracNaPotezu].Okvir.transform.colorTransform = Monopoly.ProzirnaOznakaFigurice;
			Monopoly.FiguriceZaPrikaz[igracNaPotezu].Okvir.transform.colorTransform = Monopoly.CrnaOznakaFigurice;
			if (Igraci[igracNaPotezu].UMinusu)	// ako je novi igrač na potezu slučajno u minusu (postao je indirektno, primjerice, drugi igrač je izvukao karticu šanse koja je rekla "uzmite 200 kn od svakog igrača") ...
			{
				if (Igraci[igracNaPotezu].AIIgrac)  // .. ako je igrač na potezu AI, onda će odlučiti što će dalje
					(Igraci[igracNaPotezu] as AI).OdluciOMinusu(Igraci[igracNaPotezu].Novac);
				else	// a ako nije, skrivamo gumbe za bacanje kockica i završetak poteza
				{
					Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].removeEventListener(MouseEvent.CLICK, Monopoly.BaciKockice);
					Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].alpha = 0.5;
					Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
					Igraci[igracNaPotezu].PrikaziDijalogONedostatkuNovca(Igraci[igracNaPotezu].Novac);	// prikazujemo dijalog o nedostatku novca / bankrotu
				}
			}
			
			_IgracNaPotezu = igracNaPotezu;
		}
		
		private function PronadjiBojuIgraca():uint
		{
			var indeks:uint;
			// tražimo indeks ovog igrača u polju svih igrača
			for (var i:uint = 0; i < Igraci.length; i++)
				if (Igraci[i] == this)
					indeks = i;
					
			// taj isti indeks jednak je indeksu u polju boja igraca, pa odmah možemo vratiti boju iz polja figurica na tom indeksu
			return Monopoly.FiguriceZaPrikaz[indeks].Pozadina.transform.colorTransform.color;
		}
		
		public function IdiNaPolje(indeksPolja:uint):void
		{
			const BROJ_POLJA_NA_PLOCI:uint = 40;
			// sve što trebamo je saznati koliko polja imamo od trenutne pozicije i traženog polja. I kad znamo taj broj, možemo pozvati metodu "PomakniFiguricu" iz klase figurica
			var trenutnaPozicija:uint = Figurica.Pozicija;
			var poljaZaPreci:uint = (BROJ_POLJA_NA_PLOCI - trenutnaPozicija + indeksPolja) % 40;  // Broj "BROJ_POLJA_NA_PLOCI - trenutnaPozicija" će nam reći koliko još polja imamo za preći do KRENI. Kada tom broju dodamo indeks polja na koje trebamo doći i modualrno podijelimo s 40, dobivamo ukupni broj polja koje trebamo prijeći
			
			Figurica.PomakniFiguricu(poljaZaPreci);
		}
		
		public function IdiNatragNaPolje(indeksPolja:uint):void
		{
			const BROJ_POLJA_NA_PLOCI:uint = 40;
			// sve što trebamo je saznati koliko polja imamo od trenutne pozicije i traženog polja (razliku te 2 vrijednosti). Ako je razlika negativna, broju dodajemo ukupni broj polja (40)
			var trenutnaPozicija:uint = this.Figurica.Pozicija;
			var poljaZaPreci:int = (trenutnaPozicija - indeksPolja + BROJ_POLJA_NA_PLOCI) % BROJ_POLJA_NA_PLOCI;
			
			
			Figurica.addEventListener("Rotacija za 180 gotova", PomakFigurice);
			Figurica.addEventListener(Event.ENTER_FRAME, Figurica.ZarotirajSeZa180);
			
			function PomakFigurice(e:Event):void
			{
				Figurica.removeEventListener("Rotacija za 180 gotova", PomakFigurice);
				Figurica.addEventListener("Figurica stigla na polje", RotirajFiguricu);
				Figurica.PomakniFiguricuNatrag(poljaZaPreci);
				function RotirajFiguricu(e:Event):void
				{
					Figurica.removeEventListener("Figurica stigla na polje", RotirajFiguricu);
					Figurica.addEventListener(Event.ENTER_FRAME, Figurica.ZarotirajSeZa180);
				}
			}
		}
		
		private function IstiBrojeviNaKockama(e:Event):void
		{
			// ako polje ima tri posljednja bacanja, uklanjamo prvi element iz polja (najstarije bacanje)
			if (IsteKockice.length == 3)
				IsteKockice.shift();
			
			// dodajemo najnovije bacanje (true ako su kocke iste, false ako nisu)
			if (kocka_mc.Kocke[0].currentFrame == kocka_mc.Kocke[1].currentFrame)
				IsteKockice.push(true);
			else
				IsteKockice.push(false);
				
			// ako su u svakom od tri zadnja bacanja dobivene iste kockice, resetiramo kockice i idemo u zatvor 
			if (IsteKockice.length == 3)
			{
				if (IsteKockice[0] && IsteKockice[1] && IsteKockice[2])
				{
					IsteKockice = new Vector.<Boolean>();
					UZatvoru = new Zatvor();
					UZatvoru.addEventListener("Izadji iz zatvora" + igrac_mc.IgracNaPotezu, IzadjiIzZatvora);
					this.addChild(UZatvoru);
				}
			}
		}
		
		private function PrikaziDijalogONedostatkuNovca(stariNovac:int):void 
		{
			if (! dijalog_mc.Prikazan)
				OtvoriDijalog();
			else
				Monopoly.KontejnerIgre.addEventListener("Dijalog zatvoren", OtvoriDijalog);
			
			function OtvoriDijalog(e:Event = null):void
			{
				var dijalog:dijalog_mc;
				var tekstDijaloga:String;
				
				if (e != null)
					Monopoly.KontejnerIgre.removeEventListener("Dijalog zatvoren", OtvoriDijalog);
					
				if (Novac + VrijednostDostupneImovine() > 0)
					tekstDijaloga = "Nemate više novca! Rasprodajte dio vaše imovine.";
				else
					tekstDijaloga = "Bankrotirali ste!";
					
				dijalog = new dijalog_mc(tekstDijaloga);
				
				dijalog.UkloniGumbX();
				Monopoly.KontejnerIgre.addChild(dijalog);
				dijalog.Prihvati.addEventListener(MouseEvent.CLICK, function ZatvoriDijalog(e:MouseEvent):void
				{
					var dijalog:dijalog_mc = e.currentTarget.parent as dijalog_mc;
					dijalog.Prihvati.removeEventListener(MouseEvent.CLICK, ZatvoriDijalog);
					Monopoly.KontejnerIgre.removeChild(dijalog);
					Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
					if (Novac + VrijednostDostupneImovine() <= 0)
					{
						_Novac = stariNovac;  // novac postavljamo na stari novac, jer ako je igrača do bankrota doveo drugi igrač, on mora biti u mogućnosti dobiti taj njegov stari novac
						Bankrotirao = true;  // (ima setter)
					}
				});
			}
		}
		
		private function RasprodajSveZgrade():uint 
		{
			// ova funkcija rasprodaje (banci) sve zgrade igrača koji je bankrotirao i vraća njihovu ukupnu vrijednost
			var zemljiste:Zemljiste;
			var vrijednostZgrada:uint = 0;  // novac koji će se dodijeliti igraču koji je drugog igrača doveo do bankrota. Predstavlja vrijednost svih zgrada igrača koji je bankrotirao
			var zgrada:zgrada_mc;  // u ovu će se varijablu spremati zgrade koje budemo uklanjali s ploče (sprite-ovi)
			for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
			{
				zemljiste = Zemljiste.Zemljista[i];
				if (zemljiste.Vlasnik == IgracNaPotezu)
				{
					if (zemljiste.BrojKuca > 0 && zemljiste.BrojKuca < 5)
					{
						for (var j:uint = 1; j <= zemljiste.BrojKuca; j++)
						{
							vrijednostZgrada += zemljiste.CijenaKuce / 2;  // povećavamo varijablu vrijednost zgrada za iznos polovine kuće (tj. prodajemo ju banci)
							zgrada = Monopoly.KontejnerIgre.getChildByName("zgrada_" + zemljiste.NazivPolja + j.toString()) as zgrada_mc;
							Monopoly.KontejnerIgre.removeChild(zgrada);  // uklanjamo zgradu s ploče
							Zemljiste.UkupnoKucaPreostalo++;  // povećavamo ukupni broj kuća koje se mogu kupiti
						}
					}
					else if (zemljiste.BrojKuca == 5)
					{
						vrijednostZgrada += zemljiste.CijenaKuce * 5 / 2;	// prodajna vrijednost jednog hotela
						zgrada = Monopoly.KontejnerIgre.getChildByName("zgrada_" + zemljiste.NazivPolja + "5") as zgrada_mc;
						Monopoly.KontejnerIgre.removeChild(zgrada);  // uklanjamo zgradu s ploče
						Zemljiste.UkupnoHotelaPreostalo++;  // povećavamo ukupni broj hotela koje se mogu kupiti
					}
					
					zemljiste.BrojKuca = 0;  // nakon što smo sve kuće rasprodali, postavljamo broj kuća na zemljištu na 0
				}
			}
			
			return vrijednostZgrada;
		}
		
		public function IzadjiIzZatvora(e:Event):void
		{
			UZatvoru.removeEventListener("Izadji iz zatvora" + igrac_mc.IgracNaPotezu, IzadjiIzZatvora);
			this.removeChild(UZatvoru);
			UZatvoru = null;
		}
		
		protected function VrijednostDostupneImovine():uint
		{
			// ova funkcija vraća zbroj vrijednosti svih kuća, hotela i zemljišta u vlasništvu igrača koja nisu pod hipotekom
			var vrijednost:uint = 0;
			var tmpPosjed:Posjed;
			
			for (var i:uint = 0; i < Polje.Polja.length; i++)
			{
				if (Polje.Polja[i] is Posjed)  // ako je polje posjed i ako je igrač na potezu njegov vlasnik, zbrajamo njegovu cijenu. Ako je zemljište, zbrajamo i vrijednosti svih kuća na tom zemljištu
				{
					tmpPosjed = Polje.Polja[i] as Posjed;
					if (tmpPosjed.Vlasnik == IgracNaPotezu && ! tmpPosjed.PodHipotekom)
					{
						vrijednost += tmpPosjed.Cijena;
						if (tmpPosjed is Zemljiste)
							vrijednost += (tmpPosjed as Zemljiste).BrojKuca * (tmpPosjed as Zemljiste).CijenaKuce;
					}
				}
			}
			
			return vrijednost / 2;	// vrijednost dijelimo s 2 jer zapravo za svaki posjed možemo dobiti samo pola njegove cijene (kad ga postavljamo pod hipoteku). Također, za svaku kuću ili hotel dobivamo samo pola cijene kad ih prodajemo natrag banci
		}
		
		public function get Bankrotirao():Boolean
		{
			return _Bankrotirao;
		}
		
		public function set Bankrotirao(bankrotirao:Boolean):void
		{
			// kada varijabla postane true, radimo sve ono što ide uz bankrot
			_Bankrotirao = bankrotirao;
			
			// uklanjamo bijeli prsten oko igrača
			figurica_mc.BijeliPrsten.UkloniPrstenOkoIgraca();
			
			// provjeravamo koliko je preostalo igrača koji nisu bankrotirali
			var nisuBankrotirali:Vector.<String> = new Vector.<String>();
			for (var i:uint = 0; i < Igraci.length; i++)
				if (! Igraci[i]._Bankrotirao)
					nisuBankrotirali.push(Igraci[i].Figurica.ImeFigurice);

			if (nisuBankrotirali.length == 1)	// ako je preostao još jedan igrač koji nije bankrotirao, završavamo igru!
			{
				// uklanjamo sve listenere za igru
				Monopoly.KlikanjePoPlociOnOff(false);
				Monopoly.SakrijPokaziTradeGumb(false);
				Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
				Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].removeEventListener(MouseEvent.CLICK, Monopoly.BaciKockice);
				Monopoly.UpravljackeIkone[Monopoly.KOCKICE_GUMB].alpha = 0.5;
				
				// prikazujemo dijalog da je igra gotova
				var dijalog:dijalog_mc = new dijalog_mc("Pobjednik: " + nisuBankrotirali[0] + ".\nČestitamo!");
				Monopoly.KontejnerIgre.addChild(dijalog);
				dijalog.UkloniGumbX();
				dijalog.Prihvati.visible = false;
				return;
			}
			
			if (_Bankrotirao)
			{
				Monopoly.KontejnerIgre.removeChildAt(Monopoly.KontejnerIgre.getChildIndex(this));  // uklanjamo figuricu igrača s ploče
				Monopoly.Kontejner.removeChild(Monopoly.FiguriceZaPrikaz[IgracNaPotezu]);  // također uklanjamo i igrača s desne strane (prikaz njegove figurice i prikaz njegova novca)
				Monopoly.Kontejner.removeChild(Monopoly.PrikaziNovca[IgracNaPotezu]);
				
				if (ZadnjePlacanje == -1)  // ako smo zadnje dugovali banci
				{
					// vraćamo kartice izađi iz zatvora natrag u špil (ako ih igrač ima).
					var karticaIzadjiIzZatvora:KarticaSrece = new KarticaSrece(0, "Ova karta može se sačuvati dok\nse ne upotrijebi ili se može prodati.", true);  // stvaramo novu karticu za izlazak iz zatvora koju ćemo, ako treba, vratiti u špil
					for (i = 0; i < KarticeIzadjiIzZatvora.length; i++)
					{
						if (Monopoly.PoljaSrece.TekstoviKarticaDrzavneBlagajne.indexOf(karticaIzadjiIzZatvora) == -1)  // ako u karticama državne blagajne ova kartica ne postoji (nema je), onda je ondje vraćamo. U suprotnom, vraćamo je u kartice šanse
							Monopoly.PoljaSrece.TekstoviKarticaDrzavneBlagajne.unshift(karticaIzadjiIzZatvora);
						else
							Monopoly.PoljaSrece.TekstoviKarticaSanse.unshift(karticaIzadjiIzZatvora);
					}
					
					RasprodajSveZgrade();  // sve zgrade igrača predajemo banci
					
					// banka stavlja na dražbu sve kartice
					RasprodajSvePosjedeNaAukciji();  // pozivamo rekurzivnu funkciju koja će prodavati redom posjede na aukciji
					function RasprodajSvePosjedeNaAukciji (e:Event = null) // rekurzivna funkcija koja će se izvoditi sve dok ima novih posjeda
					{
						if (e != null)
							e.currentTarget.removeEventListener("Posjed kupljen", RasprodajSvePosjedeNaAukciji);
						
						var indeksiPosjeda:Array = new Array();  // najprije ćemo u ovo polje zabilježiti sve indekse posjeda koje igrač ima
							for (i = 0; i < Polje.Polja.length; i++)
								if (Polje.Polja[i] is Posjed)
									if ((Polje.Polja[i] as Posjed).Vlasnik == IgracNaPotezu)
										indeksiPosjeda.push(i);
						
						if (indeksiPosjeda.length > 0)
						{
							var indeksTrenutnogPosjeda = indeksiPosjeda.pop();
							var trenutniPosjed:Posjed = Polje.Polja[indeksTrenutnogPosjeda] as Posjed;
							if (trenutniPosjed.PodHipotekom)  // ako je posjed pod hipotekom, uklanjamo hipoteku s njega (kako ne bi ostala kada prodamo posjed na dražbi)
							{
								trenutniPosjed.PodHipotekom = false;
								trenutniPosjed.IzradiNovuKarticuPosjeda();
							}
							var aukcija = new Aukcija(Monopoly, indeksTrenutnogPosjeda);
							Polje.Polja[indeksTrenutnogPosjeda].addEventListener("Posjed kupljen", RasprodajSvePosjedeNaAukciji);
						} else
						{
							Monopoly.ZavrsiPotez();  // i na kraju, neovisno o tome je li bio AI ili stvarni igrač, završavamo potez
						}
					}
				} 
				else  // ako smo zadnje dugovali nekom drugom igraču
				{
					// kartice izađi iz zatvora ako predajemo novom vlasniku (ukoliko ih igrač koji je bankrotirao ima)
					var KarticaZaIzlazIzZatvora:karticaSrece_mc;
					for (i = 0; i < KarticeIzadjiIzZatvora.length; i++)
					{
						KarticaZaIzlazIzZatvora = KarticeIzadjiIzZatvora[i];
						Igraci[ZadnjePlacanje].KarticeIzadjiIzZatvora.push(karticaIzadjiIzZatvora);  // karitcu dodjeljujemo novom vlasniku
					}
					
					var vrijednostZgrada = RasprodajSveZgrade();  // ova funkcija rasprodaje sve zgrade igrača koji je bankrotirao i vraća njihovu ukupnu vrijednost
					Igraci[ZadnjePlacanje].Novac += vrijednostZgrada;  // onom igraču koji je ovog igrača doveo do bankrota (o čemu govori varijabla zadnje plaćanje) povećavamo novac za vrijednost svih zgrada koje je bankrotirani igrač imao
					
					// svi posjedi se dodjeljuju novom vlasniku. Za svaki posjed koji je bio pod hipotekom, on će platiti 10% hipoteke odmah. Kasnije može vratiti hipoteku
					var posjed:Posjed;
					for (i = 0; i < Polje.Polja.length; i++)
					{
						if (Polje.Polja[i] is Posjed)
						{
							posjed = Polje.Polja[i] as Posjed;
							if (posjed.Vlasnik == IgracNaPotezu)
							{
								posjed.Vlasnik = this.ZadnjePlacanje;  // postavljamo za vlasnika posjeda onoga igrača zbog kojeg je igrač na potezu bankrotirao
								posjed.PostaviOznakuKupovine(Igraci[ZadnjePlacanje], i);  // postavljamo oznaku na posjed (dijamant)
								if (posjed.PodHipotekom)
								{
									// ako je posjed pod hipotekom ...
									Igraci[ZadnjePlacanje].ZadnjePlacanje = -1;
									Igraci[ZadnjePlacanje].Novac -= posjed.VrijednostHipoteke * 0.1;  // ... znači da će igrač koji dobije ovaj posjed morati platiti odmah 10% vrijednosti hipoteke
								}
							}
						}
					}
					
					// sav novac koji je imao igrač dajemo novom igraču
					if (_Novac > 0)
						Igraci[ZadnjePlacanje].Novac += _Novac;
						
					Monopoly.ZavrsiPotez();  // i na kraju, neovisno o tome je li bio AI ili stvarni igrač, završavamo potez
				}
			}
		}
	}
}
