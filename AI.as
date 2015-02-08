package
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.events.MouseEvent;
	
	public class AI extends igrac_mc
	{
		public var OdlukaOAukciji:int;
		private var BrojPosjedaIsteBoje:uint;
		private var BrojPosjedaIsteBojeKojeImaVlasnik:uint;
		private var BrojPosjedaIsteBojeKojeImaDrugiIgrac:uint;
		
		public function AI(figurica:figurica_mc)
		{
			super(figurica);
		}
		
		public function OdluciOKupovini():Boolean
		{
			// ako metoda vrati true, AI igrač će kupiti posjed. Ako vrati false, onda ga neće kupiti
			var posjed:Posjed = Polje.Polja[Figurica.Pozicija] as Posjed;
			var cijenaPosjeda:uint = posjed.Cijena;
			var tmpPosjed:Posjed;
			
			// tražimo koliko ima posjeda te boje na koju je AI igrač stao i koliko od tih posjeda ima AI, a koliko drugi igrači
			// Znamo da je trenutno AI na potezu, pa ćemo za njegov indeks u polju igrača iskoristiti varijablu "IgracNaPotezu"
			InformacijeOBrojuPosjeda(posjed.VrstaPolja, IgracNaPotezu);
			
			// zatim provjeravamo hoće li kupiti posjed ukoliko ima već jedan ili više posjeda iste boje / vrste
			// najprije provjeravamo ako vlasnik ima već jedan posjed te boje
			if (BrojPosjedaIsteBojeKojeImaVlasnik == 1)
			{
				if (BrojPosjedaIsteBoje == 2 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 0)
				{
					// ako je preostao još jedan posjed i nitko ga drugi nema, tada će AI sa 100% vjerojatnošću kupiti taj posjed (ukoliko ima novca naravno) (jer će tada imati monopol)
					if (this.Novac > cijenaPosjeda)
						return true;
				}
				else if (BrojPosjedaIsteBoje == 3 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 0)
				{
					// ako su preostala još 2 posjeda i nitko drugi nema nijedan od ta 2, kupit ćemo ga sa vjerojatnošću od 75% (ukoliko ima novca naravno)
					if (this.Novac > cijenaPosjeda)
						if (Math.random() < 0.75)
							return true;
				}
				else if (BrojPosjedaIsteBoje == 3 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 1)
				{
					// ako je preostao još 1 posjed, a jedan posjed već ima i drugi igrač, kupit ćemo novi posjed s vjerojatnošću od 50% (i to samo ako imamo dva puta više novca od cijene posjeda)
					if (this.Novac > cijenaPosjeda * 2)
						if (Math.random() < 0.5)
							return true;
				}
			}
			
			//ako vlasnik ima dva posjeda te boje
			if (BrojPosjedaIsteBojeKojeImaVlasnik == 2)
			{
				// posjed uzimamo definitvno, jer ćemo u tom slučaju imati monopol (naravno, ako imamo dovoljno novca)
				if (this.Novac > cijenaPosjeda)
					return true;
			}
			
			// ako drugi igrači imaju već 2 posjeda (od ukupno 3) ili 1 (od ukupno 2), a nas se pita da kupimo posljednji posjed te boje / vrste
			if (BrojPosjedaIsteBojeKojeImaDrugiIgrac == 2 || (BrojPosjedaIsteBojeKojeImaDrugiIgrac == 1 && BrojPosjedaIsteBoje == 2))
			{
				// najprije provjeravamo je li isti vlasnik ima ta oba posjeda
				var brojPosjedaIgraca:Array = new Array(0, 0, 0, 0); // na početku postavljamo broj posjeda ove boje / vrste za svakog igrača na 0 (jer ne znamo koliko koji igrač ima posjeda ove boje)
				
				// saznajemo koliko posjeda ove boje ima pojedini igrač
				for (var i:uint = 0; i < Polje.Polja.length; i++)
				{
					// provjeravamo jel ima polje ima atribut "Vlasnik", jer nemaju sva polja taj atribut. Imaju ga samo posjedi.
					if (Polje.Polja[i].hasOwnProperty("Vlasnik"))
					{
						posjed = Polje.Polja[i] as Posjed;
						if (tmpPosjed.VrstaPolja == posjed.VrstaPolja)
							if (tmpPosjed.Vlasnik != -1)
								brojPosjedaIgraca[tmpPosjed.Vlasnik]++;
					}
				}
				
				// ako jedan od igrača već SAM ima dva posjeda, onda s 90% vjerojatnošću kupujemo treći posjed (naravno, ako imamo novca)
				if (brojPosjedaIgraca.indexOf(2) != -1) // gornji uvjet zapisan na lijepi način :)
				{
					if (this.Novac > posjed.Cijena)
						if (Math.random() < 0.9)
							return true;
				}
			}
			
			// i na kraju, ako kupovina nije kritična (ako ne odgovara nijednom od ova gore tri uvjeta kupovine) ...
			// ... ako ima barem dvostruko više novca nego što košta posjed, kupiti će ga u 75% slučajeva
			if (this.Novac > cijenaPosjeda * 2)
			{
				if (Math.random() < 0.75)
					return true;
			}
			else
			{
				// ako ima 30% više novca nego što košta posjed, kupit će ga u 50% slučajeva
				if (this.Novac > cijenaPosjeda * 1.3)
					if (Math.random() < 0.5)
						return true;
			}
			
			// u svim drugi slučajevima
			return false;
		}
		
		public function OdluciOAukciji(pokretacAukcije:uint, indeksAIIgraca:uint, najvisaPonuda:uint):void
		{
			// moramo znati tko je pokretač aukcije kako bi iz toga iščitali koje polje se kupuje (preko pozicije pokretača aukcije)
			// najprije saznajemo informacije o boji posjeda koja je na aukciji - koliko ima posjeda te boje, koliko od toga ima AI te koliko imaju drugi igrači
			var pozicijaPokretacaAukcije:uint = Igraci[pokretacAukcije].Figurica.Pozicija;
			var vrstaPoljaKojeSeKupuje:uint = Polje.Polja[pozicijaPokretacaAukcije].VrstaPolja;
			var originalnaCijenaPosjedaKojiSeKupuje:uint =  (Polje.Polja[pozicijaPokretacaAukcije] as Posjed).Cijena
			InformacijeOBrojuPosjeda(vrstaPoljaKojeSeKupuje, indeksAIIgraca);
			
			// simuliramo razmišljanje AI-a (delay od 2 sekunde!)
			var tajmer:Timer = new Timer(2000, 1);
			tajmer.addEventListener(TimerEvent.TIMER, DonesiOdluku);
			tajmer.start();
			function DonesiOdluku(e:TimerEvent):void
			{
				e.currentTarget.removeEventListener(TimerEvent.TIMER, DonesiOdluku);
				(e.currentTarget as Timer).stop();
				
				if (BrojPosjedaIsteBojeKojeImaVlasnik == 1)
				{
					if (BrojPosjedaIsteBoje == 2 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 0)
					{
						// ako AI ima 1 posjed od ukupno 2, dat će i do 30% veću cijenu za posjed (ako ima 100 kuna više od trenutne najviše ponude. Zašto, eto tako da smanjimo broj generiranja random iznosa)
						PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 1.3);  // šaljemo trenutno najvišu ponudu i cijenu posjeda
						return;
					} 
					else if (BrojPosjedaIsteBoje == 3 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 0)
					{
						// ako su preostala još 2 posjeda i nitko drugi nema nijedan od ta 2, dat ćemo do 75% cijene posjeda (ukoliko ima novca naravno)
						PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 0.75);
						return;
					} 
					else if (BrojPosjedaIsteBoje == 3 && BrojPosjedaIsteBojeKojeImaDrugiIgrac == 1)
					{
						// ako je preostao još 1 posjed, a jedan posjed već ima i drugi igrač, dat ćemo do 75% cijene posjeda
						PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 0.5);
						return;
					}
				}
				
				//ako AI ima dva posjeda te boje (a treći je na aukciji) ...
				if (BrojPosjedaIsteBojeKojeImaVlasnik == 2)
				{
					// dat će i do 30% veću cijenu za posjed (ako ima 100 kuna više od trenutne najviše ponude. Zašto, eto tako da smanjimo broj generiranja random iznosa), neovisno o tome je li prvotno odustao od kupovine 
					PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 1.3);
					return;
				}
				
				// ako drugi igrači imaju već 2 posjeda (od ukupno 3) ili 1 (od ukupno 2), a na nama je red da ponudimo iznos
				if (BrojPosjedaIsteBojeKojeImaDrugiIgrac == 2 || (BrojPosjedaIsteBojeKojeImaDrugiIgrac == 1 && BrojPosjedaIsteBoje == 2))
				{
					// najprije provjeravamo je li isti vlasnik ima ta oba posjeda
					var brojPosjedaIgraca:Array = new Array(0, 0, 0, 0); // na početku postavljamo broj posjeda ove boje / vrste za svakog igrača na 0 (jer ne znamo koliko koji igrač ima posjeda ove boje)
					var posjed:Posjed = Polje.Polja[pozicijaPokretacaAukcije] as Posjed;
					
					// saznajemo koliko posjeda ove boje ima pojedini igrač
					for (var i:uint = 0; i < Polje.Polja.length; i++)
					{
						// provjeravamo jel ima polje ima atribut "Vlasnik", jer nemaju sva polja taj atribut. Imaju ga samo posjedi.
						if (Polje.Polja[i].hasOwnProperty("Vlasnik"))
						{
							var tmpPosjed:Posjed = Polje.Polja[i] as Posjed;
							if (tmpPosjed.VrstaPolja == posjed.VrstaPolja)
								if (tmpPosjed.Vlasnik != -1)
									brojPosjedaIgraca[tmpPosjed.Vlasnik]++;
						}
					}
					
					// ako jedan od igrača već SAM ima dva posjeda, onda smo spremni ponuditi i do 50% veću cijenu od originalne
					if (brojPosjedaIgraca.indexOf(2) != -1) // gornji uvjet zapisan na lijepi način :)
					{
						PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 1.5);
						return;
					}
				}
				
				// i na kraju, ako kupovina nije kritična, dat ćemo do 75% originalne cijene
				PonudiIznos(najvisaPonuda, originalnaCijenaPosjedaKojiSeKupuje, 0.75);
				return;
			}
		}
		
		private function PonudiIznos(najvisaPonuda:uint, cijenaPosjeda:uint, maxOmjerPonudaCijena:Number):void
		{
			// ovdje koristimo +50 isključivo iz razloga kako bi što prije generirali broj (kroz 10-ak pokušaja možda)
			if (this.Novac > najvisaPonuda + 50 && najvisaPonuda + 50 < cijenaPosjeda * maxOmjerPonudaCijena)
			{
				do 
				{
					// generiramo nasumični broj između najviše ponude + 1 i najviše ponude + 500
					OdlukaOAukciji = najvisaPonuda + Math.floor(Math.random() * 500) + 1;
				} while (this.Novac < OdlukaOAukciji || OdlukaOAukciji > cijenaPosjeda * maxOmjerPonudaCijena);
			} 
			else
			{
				OdlukaOAukciji = -1;
			}
			
			this.dispatchEvent(new Event("Odluka donesena"));
		}
		
		private function InformacijeOBrojuPosjeda(vrstaPolja:uint, indeksIgraca:uint):void
		{
			var tmpPosjed:Posjed;
			// tražimo koliko ima posjeda te boje na koju je AI igrač stao i koliko od tih posjeda ima AI, a koliko drugi igrači
			// Znamo da je trenutno AI na potezu, pa ćemo za njegov indeks u polju igrača iskoristiti varijablu "IgracNaPotezu"
			for (var i:uint = 0; i < Polje.Polja.length; i++)
			{
				// provjeravamo jel ima polje ima atribut "Vlasnik", jer nemaju sva polja taj atribut. Imaju ga samo posjedi.
				if (Polje.Polja[i].hasOwnProperty("Vlasnik"))
				{
					tmpPosjed = Polje.Polja[i] as Posjed;
					if (tmpPosjed.VrstaPolja == vrstaPolja)
						BrojPosjedaIsteBoje++;
					if (tmpPosjed.Vlasnik == indeksIgraca)
						BrojPosjedaIsteBojeKojeImaVlasnik++;
					else
						BrojPosjedaIsteBojeKojeImaDrugiIgrac++;
				}
			}
		}
		
		public function OdlukaUZatvoru():void
		{
			if (KarticeIzadjiIzZatvora.length > 0)	// ako ima karticu "izađi iz zatvora, iskoristit će na nju"
			{
				UZatvoru.KliknutoNaKarticu();
				Monopoly.BaciKockice();
			}
			else									// u suprotnom će bacati kockice dok može, a kad ne bude više mogao, platit će kaznu od 1000 kuna (to je definirano u klasi "Zatvor")
			{
				if (UZatvoru.PreostaliBrojBacanja > 0)
					Monopoly.BaciKockice();
			}
		}
		
		public function OdlukaOKupoviniZgrada():void
		{
			var bojeZaGradnju:Array = new Array();	// u ovo polje ćemo postavljati polja koja će sadržavati indekse polja iste boje
			// prvo pronalazimo sve one boje (tj. njihove posjede) od kojih AI ima sve posjede (i pritom mu nijedna kuća nije pod hipotekom).
			var tmpBoja:uint = Polje.Polja[1].VrstaPolja; // Za to će nam trebati privremena varijabla boje. U nju ćemo spremati trenutnu boju koju razmatramo. Ovu varijablu inicijaliziramo na prvo smeđe polje (Jeretova ulica; indeks 1)
			var imaSvePosjedeIsteBoje:Boolean = true;	// Za to će nam također trebati i varijabla koja će govoriti o tome ima li AI sve posjede iste boje. Inicijaliziramo i nju
			var poljaIsteBoje:Array = new Array();  // ovo polje ćemo pohranjivati u polje bojeZaGradnju ako AI bude imao sve posjede iste boje
			var podHipotekom:Array = new Array();
			for (var i:uint = 1; i < Polje.Polja.length; i++)	// petlja kreće od 2. elementa (indeks 1) jer nema smisla provjeravati polje kreni
			{
				if (Polje.Polja[i] as Posjed)  // ovdje ćemo provjeriti sve posjede u vlasništvu igrača koji su pod hipotekom i pohraniti ih u polje "podHipotekom"
				{
					if ((Polje.Polja[i] as Posjed).Vlasnik == IgracNaPotezu && (Polje.Polja[i] as Posjed).PodHipotekom)
						podHipotekom.push(i);
				}
				
				if (Polje.Polja[i] is Zemljiste)
				{
					if (Polje.Polja[i].VrstaPolja == tmpBoja)  // ako je polje iste boje kao tmpboja
					{
						if ((Polje.Polja[i] as Zemljiste).Vlasnik == IgracNaPotezu && ! (Polje.Polja[i] as Zemljiste).PodHipotekom)  // ... i ako je vlasnik igrač na potezu (AI) i zemljište nije pod hipotekom
							poljaIsteBoje.push(i);
						else
							imaSvePosjedeIsteBoje = false; // a u suprotnom, postavljamo ovu varijablu na false
					} 
					else  // ako pronađemo zemljište koje nije iste boje kao tmpBoja, znači da smo naišli na novu boju na ploči (sve su postavljene redom). U tom slučaju ....
					{
						tmpBoja = Polje.Polja[i].VrstaPolja;  // ... mijenajmo privremenu boju na novu boju zemljišta
						if (imaSvePosjedeIsteBoje)  // ako AI ima sve posjede iste boje, polje s indeksima zemljišta te boje pohranjujemo u globalno polje "bojeZaGradnju"
							bojeZaGradnju.push(poljaIsteBoje);
						imaSvePosjedeIsteBoje = true;  // ovu vrijednost ponovno vraćamo na true
						poljaIsteBoje = new Array();  // praznimo polje s indeksima iste boje
						poljaIsteBoje.push(i);  // i u njega umećemo novi indeks
					}
				}
			}
			
			// ova gore for petlja nije ništa provjerila za stradun i ilicu (jer se nije promijenila boja poslije njih, pa to sada činimo ručno)
			if (imaSvePosjedeIsteBoje)
				bojeZaGradnju.push(poljaIsteBoje);
			
			// kada smo pronašli tražene posjede, reversamo polje (kako bi dobili prvo najskuplje posjede!)
			bojeZaGradnju.reverse();
			
			// i kupujemo kuće. AI će u svakom potezu s vjerojatnošću od 50% pokušati kupiti neku kuću, ukoliko ima 30% više novca nego što ona košta
			var vjerojatnostKupovine:Number = Math.random();			
			var kucaKupljena:Boolean = false;	// ova varijabla će nam služiti iskljčivo za to da pobjegnemo iz dvije ugniježđene for petlje nakon što kupimo kuću, zato jer želimo unutar jedne while petlje izgraditi samo 1 kuću!
			while (vjerojatnostKupovine < 0.5)
			{
				for (i = 0; i < bojeZaGradnju.length; i++)	// krećemo od prve boje (najskuplje pa sve do najjeftinijih)
				{
					bojeZaGradnju[i].reverse();
					for (var j:uint = 0; j < bojeZaGradnju[i].length; j++)  // u toj boji idemo redom po kućama
					{
						var zemljiste:Zemljiste = Polje.Polja[bojeZaGradnju[i][j]] as Zemljiste;	// iz indeksa polja izvlačimo zemljište
						if (GradnjaKuceMoguca(bojeZaGradnju[i], bojeZaGradnju[i][j]) && this.Novac >= zemljiste.CijenaKuce * 1.3)  // ako je gradnja na zemljištu moguća i AI ima barem 30% više novca od cijene kuće
						{
							zemljiste.BrojKuca++;
							this.ZadnjePlacanje = -1;
							this.Novac -= zemljiste.CijenaKuce;
							var brojVecIzgradjenihKuca:uint = zemljiste.BrojKuca;  // predstavlja broj već izgrađenih kuća na zemljištu boje i, indeksa j
							if (brojVecIzgradjenihKuca < 5)		// ako je taj broj manji od četiri, samo gradimo novu kuću
							{
								zemljiste.IzgradiNovuKucu(brojVecIzgradjenihKuca);
								Zemljiste.UkupnoKucaPreostalo--;
							}
							else	// ako imamo točno četiri kuće, znači da moramo graditi hotel
							{
								// prvo uklanjamo četiri postojeće kuće
								var kuca:zgrada_mc;
								for (i = 1; i <= 4; i++)
								{
									kuca = Monopoly.KontejnerIgre.getChildByName("zgrada_" + zemljiste.NazivPolja + i.toString()) as zgrada_mc;
									Monopoly.KontejnerIgre.removeChild(kuca);
									Zemljiste.UkupnoKucaPreostalo++;
								}
								zemljiste.IzgradiNoviHotel(); // a potom gradimo novi hotel
								Zemljiste.UkupnoHotelaPreostalo--;
							}
							kucaKupljena = true;
							break;
						}
					}
					if (kucaKupljena)  // ako smo kupili kuću, iskačemo i iz ove petlje i vraćamo se na kraj while petlje gdje ponovno generiramo broj koji će nam reći hoće li se while petlja nastaviti izvršavati
					{
						kucaKupljena = false;
						break;
					}
				}
				vjerojatnostKupovine = Math.random();
			}
			
			// AI će nakon kupovine kuća pokušati vraćati hipoteke
			var hipoteka:uint;
			vjerojatnostKupovine = Math.random();
			while (vjerojatnostKupovine > 0.5 && podHipotekom.length > 0)
			{
				while (podHipotekom.length > 0)
				{
					hipoteka = podHipotekom.pop();
					if (_Novac > 2 * (Polje.Polja[hipoteka] as Posjed).VrijednostHipoteke * 1.1)
					{
						(Polje.Polja[hipoteka] as Posjed).PodHipotekom = false;
						Novac -= (Polje.Polja[hipoteka] as Posjed).VrijednostHipoteke * 1.1;
						(Polje.Polja[hipoteka] as Posjed).PostaviOznakuKupovine(this, hipoteka);
						break;	// kada vratimo jednu hipoteku, izlazimo iz unutarnje petlje te dopuštamo vanjskoj petlji da odradi svoj posao
					}
				}
				vjerojatnostKupovine = Math.random();
			}
			
			
			// INTERNA FUNKCIJA
			function GradnjaKuceMoguca(posjediIsteBoje:Array, mjestoGradnje:int):Boolean
			{
				var brojKucaNaMjestuGradnje:uint = (Polje.Polja[mjestoGradnje] as Zemljiste).BrojKuca;
				var tmpBrojKuca:uint;
				
				if (brojKucaNaMjestuGradnje == 5)
					return false;
					
				if (brojKucaNaMjestuGradnje == 4 && Zemljiste.UkupnoHotelaPreostalo == 0)
					return false;
					
				if (brojKucaNaMjestuGradnje < 4 && Zemljiste.UkupnoKucaPreostalo == 0)
					return false;
				
				for (var i:uint = 0; i < posjediIsteBoje.length; i++)
				{
					tmpBrojKuca = (Polje.Polja[posjediIsteBoje[i]] as Zemljiste).BrojKuca;
					if (Math.abs(brojKucaNaMjestuGradnje + 1 - tmpBrojKuca) > 1)
						return false;
				}
				return true;
			}
		}
		
		public function OdluciOMinusu(noviNovac:int, stariNovacpoznat:Boolean = false, stariNovac:int = 0):void  // varijabla stariNovacPoznat će nam reći znamo li vrijednost novca prije nego što je on otišao ispod nule. U slučaju kada igrač indirektno ode u bankrot nećemo znati. noviNovac je novac igrača nakon što je ušao u minus, a starinovac prije nego što je ušao u minus (ako ga znamo uopće)
		{
			if (noviNovac + VrijednostDostupneImovine() <= 0) // ako je bankrotirao
			{
				if (stariNovacpoznat)
					_Novac = stariNovac;
				var dijalog:dijalog_mc = new dijalog_mc("Igrač \"" + Figurica.ImeFigurice + "\" je bankrotirao!");
				dijalog.UkloniGumbX();
				Monopoly.KontejnerIgre.addChild(dijalog);
				dijalog.Prihvati.addEventListener(MouseEvent.CLICK, function ZatvoriDijalog(e:MouseEvent)
				{
					var dijalog:dijalog_mc = e.currentTarget.parent as dijalog_mc;
					dijalog.Prihvati.removeEventListener(MouseEvent.CLICK, ZatvoriDijalog);
					Monopoly.KontejnerIgre.removeChild(dijalog);
					Bankrotirao = true;
				});
			}
			else // ako je pred bankrotom, ali još se može izvući
			{
				// najprije će pokušati podići hipoteke gdje može. Ali prvo u polje hipoteke postavljamo parove ili trojke zemljišta (određene boje) gdje je moguće podići hipoteku
				var hipoteke:Array = new Array();
				var posjediIsteBoje:Array = new Array();
				var trenutnaBoja:uint = Zemljiste.Zemljista[0].VrstaPolja;
				var mogucePodiciHipotekuNaBoji:Boolean = true;
				var bojeSKucama:Array = new Array();
				for (var i:uint = 0; i < Polje.Polja.length; i++)
				{
					if (Polje.Polja[i] is Zemljiste)
					{
						var zemljiste:Zemljiste = Polje.Polja[i] as Zemljiste;
						if (zemljiste.Vlasnik == IgracNaPotezu)
						{
							if (zemljiste.VrstaPolja == trenutnaBoja)  // ako je boja posjeda jednaka trenutnoj boji
							{
								if (zemljiste.BrojKuca > 0)  // ako na posjedu postoji ijedna kuća, tada nije moguće podići hipoteku na toj boji
								{
									mogucePodiciHipotekuNaBoji = false;
									bojeSKucama.push(zemljiste.VrstaPolja);  // također u polje boje s kućama dodajemo ovu boju
								} else
								if (! zemljiste.PodHipotekom)
									posjediIsteBoje.push(i);  // ako posjed već nije pod hipotekom, stavljamo ga u polje posjeda iste boje
							}
							else  // a ako smo prešli na posjed nove boje
							{
								trenutnaBoja = zemljiste.VrstaPolja;  // postavljamo novu trenutnu boju
								if (mogucePodiciHipotekuNaBoji)  // ako je bilo moguće podići hipoteku na poljima prethodne boje, dodajemo polje posjeda te boje u polje "hipoteke"
									hipoteke = hipoteke.concat(posjediIsteBoje);
								mogucePodiciHipotekuNaBoji = true;  // u svakom slučaju, za novu boju postavljamo da je moguće podići hipoteku na njoj (i to će tako ostat dok se ne uvjerimo u suprotno)
								posjediIsteBoje = new Array();  // također praznimo posjede iste boje jer smo prešli na novu boju
								posjediIsteBoje.push(i);  // i u ovo polje dodajemo trenutni posjed u razmatranju (prvi posjed određene boje)
							}
						}
					}
				}
				
				// ova petlja nam nije ubacila posljednju boju vlasnika u polje hipoteka, pa ćemo to morati uraditi sami
				if (mogucePodiciHipotekuNaBoji)  // za posljednju boju (tamnoplavu)
					hipoteke = hipoteke.concat(posjediIsteBoje);
					
				// nakon što smo pronašli gdje se na zemljišta mogu podići hipoteke, isto ćemo napraviti i za komunalne ustanove i željezničke stanice	
				// zašto to nismo radili u prethodnoj petlji? Jer želimo da nam se na njih najzadnje podignu hipoteke jer donose najviše novca od svih
				for (i = 0; i < Polje.Polja.length; i++)
				{
					if (Polje.Polja[i] is KomunalnaUstanova)
					{
						var komunalna:KomunalnaUstanova = Polje.Polja[i] as KomunalnaUstanova;
						if (komunalna.Vlasnik == IgracNaPotezu)
						{
							if (! komunalna.PodHipotekom)
								hipoteke.push(i);
						}
					}
				}
				
				// na poslijetku, u polje stavljamo i sve željezničke stanice na koje je moguće postaviti hipoteku
				for (i = 0; i < Polje.Polja.length; i++)
				{
					if (Polje.Polja[i] is ZeljeznickaStanica)
					{
						var zeljeznica:ZeljeznickaStanica = Polje.Polja[i] as ZeljeznickaStanica;
						if (zeljeznica.Vlasnik == IgracNaPotezu)
						{
							if (! zeljeznica.PodHipotekom)
								hipoteke.push(i);
						}
					}
				}
				
				// krećemo s postupkom "izvlačenja iz bankrota"
				while (noviNovac <= 0 && hipoteke.length > 0)
				{
					var hipoteka:uint = hipoteke.shift();
					(Polje.Polja[hipoteka] as Posjed).PodHipotekom = true;
					noviNovac += (Polje.Polja[hipoteka] as Posjed).VrijednostHipoteke;
					(Polje.Polja[hipoteka] as Posjed).PostaviOznakuKupovine(this, hipoteka);
				}
				
				if (noviNovac > 0)
				{
					this.Novac = noviNovac;
					return;
				}
				
				// ako još nismo vratili minus, ni nakon što smo rasprodali sve posjede koje smo mogli, vrijeme je da rasprodamo kuće
				var posjediSKucama:Array = new Array();
				var zgrada:zgrada_mc;
				var rusenjeIgdjeMoguce:Boolean = true;  // ova varijabla će nam reći je li rušenje bilo gdje moguće. Rušenje može biti onemogućeno jer primjerice imamo na nekim mjestima hotel, a da bi ga srušili, trebaju nam 4 kućice. Ako u banci nema kućica, rušenje nije moguće
				while (rusenjeIgdjeMoguce && noviNovac <= 0)
				{
					for (i = 0; i < Polje.Polja.length; i++)
					{
						if (Polje.Polja[i] is Zemljiste)
						{
							zemljiste = Polje.Polja[i] as Zemljiste;
							if (bojeSKucama.indexOf(zemljiste.VrstaPolja) != -1)  // ako na ovoj boji postoji ijedna kuća ....
							{
								if (RusenjeKuceMoguce(i))  // ako je rušenje kuće moguće, na što će odgovorit interna funkcija, rušimo kuću
								{
									if (zemljiste.BrojKuca < 5) // ako na zemljištu nije hotel
									{
										zgrada = Monopoly.KontejnerIgre.getChildByName("zgrada_" + zemljiste.NazivPolja + zemljiste.BrojKuca.toString()) as zgrada_mc;
										Monopoly.KontejnerIgre.removeChild(zgrada);
										zemljiste.BrojKuca--;
										noviNovac += zemljiste.CijenaKuce / 2;
										Zemljiste.UkupnoKucaPreostalo++;
									} else  // ako na zemljištu jest hotel, moramo provjeriti ima li dovoljno kuća preostalo da ga srušimo
									{
										if (Zemljiste.UkupnoKucaPreostalo >= 4)  // hotel smijemo srušiti samo ako je preostalo više od 4 kućice
										{
											zgrada = Monopoly.KontejnerIgre.getChildByName("zgrada_" + zemljiste.NazivPolja + "5") as zgrada_mc;
											Monopoly.KontejnerIgre.removeChild(zgrada);
											zemljiste.BrojKuca--;
											noviNovac += zemljiste.CijenaKuce / 2;
											Zemljiste.UkupnoHotelaPreostalo++;
											for (var j:uint = 1; j <= 4; j++)
											{
												zemljiste.IzgradiNovuKucu(i);
												Zemljiste.UkupnoKucaPreostalo--;
											}
										}
									}
									
									break;  // nakon što srušimo kuću, izlazimo iz for petlje
								}
							}
						}
					}
					
					// ovaj dio će provjeriti je li na bilo kojem mjestu dalje moguće srušiti kuću. Daljnje rušenje neće biti moguće ako su vlasniku preostali samo hoteli, a preostali broj kućica u banci je manji od 4, ili ako nema više kućica
					var vlasnikImaHotela = false;
					var vlasnikImaKucica = false;
					for (i = 0; i < Polje.Polja.length; i++)
					{
						if (Polje.Polja[i] is Zemljiste)
						{
							zemljiste = Polje.Polja[i] as Zemljiste;
							if (zemljiste.Vlasnik == IgracNaPotezu)
							{
								if (zemljiste.BrojKuca < 5 && zemljiste.BrojKuca > 0  && RusenjeKuceMoguce(i))  // provjeravamo ona zemljišta kojih je AI vlasnik - imaju li kućica. Ako ima još kućica na nekom polju i rušenje na tom polju je moguće, varijabla "vlasnik ima kućica" će nam biti true. U suprotnom će ostati false
									vlasnikImaKucica = true;
								if (zemljiste.BrojKuca == 5)
									vlasnikImaHotela = true;
							}
						}
					}
					
					if (! vlasnikImaKucica && vlasnikImaHotela && Zemljiste.UkupnoKucaPreostalo < 4)  // ako su preostali samo hoteli (i kućice koje ionako ne možemo srušiti), a ukupno kućica u banci preostalo je manji od 4 (ne možemo srušiti niti jedan hotel, završavamo s rušenjem
						rusenjeIgdjeMoguce = false;
					if (! vlasnikImaKucica && ! vlasnikImaHotela)  // ako vlasnik više nema ni kućica ni hotela, rušenje nije moguće
						rusenjeIgdjeMoguce = false;
				}
				
				
				if (noviNovac > 0)
				{
					this.Novac = noviNovac;
					return;
				}
				
				// ako novac još nije iznad nule, preostaje nam još samo da podignemo hipoteke na zemljišta čije smo kuće prodali
				var hipotekeIgdjeMoguce:Boolean = false;
				do
				{
					for (i = 0; i < Polje.Polja.length; i++)
					{
						if (Polje.Polja[i] is Zemljiste)
						{
							zemljiste = Polje.Polja[i] as Zemljiste;
							if (zemljiste.Vlasnik == IgracNaPotezu)
							{
								if (MogucePodiciHipoteku(i))
								{
									(Polje.Polja[i] as Posjed).PodHipotekom = true;
									noviNovac += (Polje.Polja[i] as Posjed).VrijednostHipoteke;
									(Polje.Polja[i] as Posjed).PostaviOznakuKupovine(this, i);
									break;
								}
							}
						}
					}
					
					// ovaj dio će provjeravati jel na bilo kojem mjestu moguće još podići hipoteku
					for (i = 0; i < Polje.Polja.length; i++)
					{
						if (Polje.Polja[i] is Zemljiste)
						{
							if (MogucePodiciHipoteku(i))
								hipotekeIgdjeMoguce = true;
						}
					}
							
				} while (noviNovac <= 0 && hipotekeIgdjeMoguce)
				
				if (noviNovac > 0)  // ako i dalje nismo iznad nule, onda smo bankrotirali
					this.Novac = noviNovac;
				else
					Bankrotirao = true;
			}
			
			
			// INTERNA FUNKCIJA
			function RusenjeKuceMoguce(indeksZemljista:uint):Boolean
			{
				var zemljiste:Zemljiste;
				var posjediIsteBoje:Array = new Array();
				for (var i:uint = 0; i < Polje.Polja.length; i++)
				{
					if (Polje.Polja[i] is Zemljiste)
					{
						zemljiste = Polje.Polja[i] as Zemljiste;
						if (zemljiste.VrstaPolja == Polje.Polja[indeksZemljista].VrstaPolja)
							posjediIsteBoje.push(i);
					}
				}
				
				var brojKucaNaTrazenomPosjedu:uint = (Polje.Polja[indeksZemljista] as Zemljiste).BrojKuca;
				if (brojKucaNaTrazenomPosjedu - 1 < 0)
					return false;  // jer na posjedu ni nema kuća
					
				for (i = 0; i < posjediIsteBoje.length; i++)
					if (Math.abs((Polje.Polja[posjediIsteBoje[i]] as Zemljiste).BrojKuca - (brojKucaNaTrazenomPosjedu - 1)) > 1)
						return false;  // nemoguće srušiti kuću jer nakon toga ne bi bile ravnomjerno sagrađene
						
				return true;
			}
			
			// INTERNA FUNKCIJA
			function MogucePodiciHipoteku(indeksZemljista:uint):Boolean
			{
 				var trazenaBoja:uint = Polje.Polja[indeksZemljista].VrstaPolja;
				
				if ((Polje.Polja[indeksZemljista] as Zemljiste).PodHipotekom)  // ako je zemljište već pod hipotekom, nije moguće
					return false;
				
				for (var i:uint = 0; i < Polje.Polja.length; i++)
				{
					if (trazenaBoja == Polje.Polja[i].VrstaPolja)
					{
						if ((Polje.Polja[i] as Zemljiste).BrojKuca > 0)  // ako bilo koje zemljište te boje ima kuću, također nije moguće
						return false;
					}
				}
				return true;  // u svakom drugom slučaju jest moguće
			}
		}
		
		public function OdlukaORazmjeni(karticeZaRazmjenu:Array, karticeIzadjiIzZatvora:Array, mojNovac:uint, njegovNovac:uint, idAIIgraca:uint, idDrugogIgraca:uint):Boolean
		{
			// AI ce odluke donositi na temelju vrijednosti. Sve će imati svoju ponderiranu vrijednost. Prihvatit će ponudu samo ako je ukupna vrijednost koju će primiti veća ili jednaka 80% vrijednosti koju ponudi drugi igrač
			const VECI_PONDER:uint = 2;
			const MANJI_PONDER:Number = 1.5;
			const VRIJEDNOST_KARTICE_ZATVORA:uint = 750;
			var vrijednostMojePonude:uint = 0;
			var vrijednostNjegovePonude:uint = 0;
			// najprije saznajemo koje kartice posjeda (koje su uključene u razmjenu) ima AI, a koje drugi igrač
			var mojeKarticePosjeda:Array = new Array();
			var njegoveKarticePosjeda:Array = new Array();
			for (var i:uint = 0; i < karticeZaRazmjenu.length; i++)
			{
				if ((Polje.Polja[karticeZaRazmjenu[i]] as Posjed).Vlasnik == idAIIgraca)
					mojeKarticePosjeda.push(karticeZaRazmjenu[i]);
				else
					njegoveKarticePosjeda.push(karticeZaRazmjenu[i]);
			}
			
			// potom saznajemo koje kartice iz zatvora pripadaju kome
			var brojMojihKarticaIzadjiIzZatvora:uint = 0;
			var brojNjegovihKarticaIzadjiIzZatvora:uint = 0;
			
			for (i = 0; i < karticeIzadjiIzZatvora.length; i++)
			{
				if (karticeIzadjiIzZatvora[i].uRazmjeni)
				{
					if (karticeIzadjiIzZatvora[i].igrac == idAIIgraca)
						brojMojihKarticaIzadjiIzZatvora++;
					else
						brojNjegovihKarticaIzadjiIzZatvora++;
				}
			}
			
			// najprije pregledamo sve kartice posjeda AI igrača
			var tmpPosjed:Posjed;
			for (i = 0; i < mojeKarticePosjeda.length; i++)
			{
				tmpPosjed = Polje.Polja[mojeKarticePosjeda[i]] as Posjed;
				if (tmpPosjed is Zemljiste || tmpPosjed is KomunalnaUstanova)
				{
					// ako drugom igraču baš fali ta moja jedna kartica da ima monopol, njezina se vrijednost množi s većim ponderom
					if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) - BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 1)
					{
						vrijednostMojePonude += tmpPosjed.Cijena * VECI_PONDER;
					}
					else if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) == 3)
					{
						// ako drugi igrač ima 1/3 posjeda koja ja imam 2/3, tada se cijena polja množi s većim ponderom
						if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 2 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 1)
							vrijednostMojePonude += tmpPosjed.Cijena * MANJI_PONDER;
						// ako drugi igrač nema polja koja ja imam 2/3, tada je očito da ne želi dopustiti da imam monopol, zbog čega će se cijena posjeda množiti s većim ponderom
						else if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 2 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 0)
							vrijednostMojePonude += tmpPosjed.Cijena * VECI_PONDER;
						else
							vrijednostMojePonude += tmpPosjed.Cijena;
					}
					else if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) == 2)
					{
						// ako drugi igrač nema posjeda koja ja imam 1/2, tada je očito da ne želi dopustiti da imam monopol, zbog čega će se cijena posjeda množiti s većim ponderom
						if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 1 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 0)
							vrijednostMojePonude += tmpPosjed.Cijena * VECI_PONDER;
						else
							vrijednostMojePonude += tmpPosjed.Cijena;
					}
				} else // ako je posjed željeznica
				{
					vrijednostMojePonude += tmpPosjed.Cijena * MANJI_PONDER;
				}
			}
			// toj vrijednosti ponude pribrajamo i vrijednosti kartica "Izadji iz zatvora" te ponuđeni novac
			vrijednostMojePonude += brojMojihKarticaIzadjiIzZatvora * VRIJEDNOST_KARTICE_ZATVORA;
			vrijednostMojePonude += mojNovac;
			
			// potom pregledamo sve kartice posjeda drugog igrača
			for (i = 0; i < njegoveKarticePosjeda.length; i++)
			{
				tmpPosjed = Polje.Polja[njegoveKarticePosjeda[i]] as Posjed;
				if (tmpPosjed is Zemljiste || tmpPosjed is KomunalnaUstanova)
				{
					// ako AI igraču baš fali ta jedna kartica drugog igrača da ima monopol, njezina se vrijednost množi s većim ponderom
					if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) - BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 1)
					{
						vrijednostNjegovePonude += tmpPosjed.Cijena * VECI_PONDER;
					}
					else if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) == 3)
					{
						// ako AI igrač ima 1/3 posjeda koje drugi igrač ima 2/3, tada se cijena polja množi s većim ponderom
						if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 2 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 1)
							vrijednostNjegovePonude += tmpPosjed.Cijena * MANJI_PONDER;
						// ako ai igrač nema polja koja drugi igrač ima 2/3, tada je očito da ne želi dopustiti da drugi igrač ima monopol, zbog čega će se cijena posjeda množiti s većim ponderom
						else if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 2 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 0)
							vrijednostNjegovePonude += tmpPosjed.Cijena * VECI_PONDER;
						else
							vrijednostNjegovePonude += tmpPosjed.Cijena;
					}
					else if (BrojPosjedaNekeVrste(tmpPosjed.VrstaPolja) == 2)
					{
						// ako ai igrač nema polja koja drugi igrač ima 1/2, tada je očito da ne želi dopustiti da drugi igrač ima monopol, zbog čega će se cijena posjeda množiti s većim ponderom
						if (BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idDrugogIgraca) == 1 && BrojPosjedaNekeVrsteKojuImaVlasnik(tmpPosjed.VrstaPolja, idAIIgraca) == 0)
							vrijednostNjegovePonude += tmpPosjed.Cijena * VECI_PONDER;
						else
							vrijednostNjegovePonude += tmpPosjed.Cijena;
					}
				} else // ako je posjed željeznica
				{
					vrijednostNjegovePonude += tmpPosjed.Cijena * MANJI_PONDER;
				}
			}
			// toj vrijednosti ponude pribrajamo i vrijednosti kartica "Izadji iz zatvora" te ponuđeni novac
			vrijednostNjegovePonude += brojNjegovihKarticaIzadjiIzZatvora * VRIJEDNOST_KARTICE_ZATVORA;
			vrijednostNjegovePonude += njegovNovac;
			
			if (vrijednostMojePonude <= vrijednostNjegovePonude)
				return true;
			else
				return false;
		}
		
		private function BrojPosjedaNekeVrste(vrsta:uint):uint
		{
			var broj:uint = 0;
			for (var i:uint = 0; i < Polje.Polja.length; i++)
				if (Polje.Polja[i].VrstaPolja == vrsta)
					broj++;
					
			return broj;
		}
		
		private function BrojPosjedaNekeVrsteKojuImaVlasnik(vrsta:uint, vlasnik:uint):uint
		{
			var broj:uint = 0;
			var tmpPosjed:Posjed;
			for (var i:uint = 0; i < Polje.Polja.length; i++)
			{
				if (Polje.Polja[i] is Posjed)
				{
					tmpPosjed = Polje.Polja[i] as Posjed;
					if (tmpPosjed.VrstaPolja == vrsta && tmpPosjed.Vlasnik == vlasnik)
						broj++;
				}
			}
			return broj;
		}
	}
}
