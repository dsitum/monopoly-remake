package  {	
	import com.greensock.*;
	import com.greensock.easing.Linear;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	import flash.events.MouseEvent;
	
	public class PoljeSrece {
		private const DRZAVNA_BLAGAJNA:uint = 10;  // karticama šanse i državne blagajne dodjeljujemo jednake indekse kao što su u klasi Polja (za lakše baratanje)
		private const SANSA:uint = 11;
		public var Monopoly:Igra;
		public var TekstoviKarticaDrzavneBlagajne:Vector.<KarticaSrece> = new Vector.<KarticaSrece>();
		public var TekstoviKarticaSanse:Vector.<KarticaSrece> = new Vector.<KarticaSrece>();
		private var LiceKartice:karticaSrece_mc = new karticaSrece_mc();  // ove dvije varijable će se koristiti za prikaz animacije kad se stane na polje šanse ili državne blagajne
		private var NalicjeKartice:karticaSrece_mc = new karticaSrece_mc();
		private var InformacijeOKartici:KarticaSrece;
		private var MatricaLicaKartice:Matrix;
		private var IgracNaPotezu:igrac_mc;
		private var Odabir:dijalog_mc;  // ove dvije varijable Odabira će služiti samo za jednu karticu državne blagajne - kada možemo birati želimo li platiti 200 kuna ili uzeti karticu šanse
		private var OdabirNovacIliSansa:karticaSrece_mc; 
		private var EventZaIskljuciti:String;
		
		public function PoljeSrece() {
			PopuniKarticeSrece();
		}
		
		private function PopuniKarticeSrece():void
		{
			// popunjavanje kartica državne blagajne
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(0, "Ova karta može se sačuvati dok\nse ne upotrijebi ili se može prodati.", true));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(1, "Povrat poreza na dobit:\nuzmite 400 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(2, "Idite natrag na Jeretovu Ulicu"));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(3, "Platite bolnicu 2000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(4, "Podignite kamate na\n7% prioritetnih dionica:\n500 Kn"));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(5, "Doktorov račun.\nPlatite 1000 Kn"));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(6, "Idite na KRENI."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(7, "Idite u ZATVOR.\nPomaknite se direktno u ZATVOR.\nAko prelazite KRENI,\nne uzimajte 4000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(8, "Naslijedili ste 2000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(9, "Platite osiguranje 1000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(10, "Rođendan vam je.\nUzmite 200 Kn od svakog igrača."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(11, "Godišnji prihod.\nUzmite 2000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(12, "Dobili ste drugu nagradu na natječaju ljepote.\nUzmite 200 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(13, "Platite kaznu 200 Kn ili uzmite karticu ŠANSE."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(14, "Greška u banci u vašu korist:\nuzmite 4000 Kn."));
			TekstoviKarticaDrzavneBlagajne.push(new KarticaSrece(15, "Od prodaje dionica dobivate\n1000 Kn."));
			
			// popunjavanje kartica šanse
			TekstoviKarticaSanse.push(new KarticaSrece(0, "Ova karta može se sačuvati dok\nse ne upotrijebi ili se može prodati.", true));
			TekstoviKarticaSanse.push(new KarticaSrece(1, "Banka vam plaća dividendu od 1000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(2, "Vraća se vaša posudba za izgradnju.\nUzmite 3000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(3, "Idite do Ilice."));
			TekstoviKarticaSanse.push(new KarticaSrece(4, "Idite do Riječkog glavnog kolodvora.\nAko prelazite kreni, uzmite 4000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(5, "Kazna za vožnju pod utjecajem alkohola.\nPlatite 400 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(6, "Idite na KRENI."));
			TekstoviKarticaSanse.push(new KarticaSrece(7, "Idite u ZATVOR.\nPomaknite se direktno u ZATVOR.\nAko prelazite KRENI,\nne uzimajte 4000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(8, "Idite na Ulicu J. P. Kamova.\nAko prelazite KRENI, uzmite 4000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(9, "Plaćate porez za popravak ulica:\n800 Kn po kući\n2300 Kn po hotelu"));
			TekstoviKarticaSanse.push(new KarticaSrece(10, "Renovirajte sve svoje zgrade.\nZa svaku kuću platite 500 Kn.\nZa svaki hotel platite 2000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(11, "Kazna za prebrzu vožnju.\nPlatite 300 Kn"));
			TekstoviKarticaSanse.push(new KarticaSrece(12, "Vratite se za 3 polja."));
			TekstoviKarticaSanse.push(new KarticaSrece(13, "Platite školarinu 3000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(14, "Dobili ste nagradu za rješenje križaljke.\nUzmite 2000 Kn."));
			TekstoviKarticaSanse.push(new KarticaSrece(15, "Idite na Trg pučkih kapetana.\nAko prelazite KRENI, uzmite 4000 Kn."));
			
			IzmijesajKarticeSrece(TekstoviKarticaDrzavneBlagajne);
			IzmijesajKarticeSrece(TekstoviKarticaSanse);
		}
		
		private function IzmijesajKarticeSrece(vrstaKartica:Vector.<KarticaSrece>):void
		{
			var nasumicniIndeks:uint;
			var tmp:KarticaSrece;
			
			for (var i:uint = vrstaKartica.length - 1; i > 0; i--)
			{
				nasumicniIndeks = Math.floor(Math.random() * (i + 1));
				tmp = vrstaKartica[i];
				vrstaKartica[i] = vrstaKartica[nasumicniIndeks];
				vrstaKartica[nasumicniIndeks] = tmp;
			}
		}
		
		public function OtvoriKarticuSrece(tipKartice:uint):void  // tip kartice može biti šansa ili državna blagajna
		{
			const BRZINA_OKRETANJA_KARTICE:Number = 0.3;
			
			// prije nego što otvorimo karticu sreće, moramo ukloniti listener za "end turn" gumb (naravno, ako je osoba od krvi i mesa na potezu)
			Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
			
			// najprije dodajemo karticu šanse ili državne blagajne stage te ju postavljamo
			Monopoly.KontejnerIgre.addChild(LiceKartice);
			Monopoly.KontejnerIgre.addChild(NalicjeKartice);
			LiceKartice.gotoAndStop(3);  // frame s tekstom kartice sreće
			LiceKartice.alpha = 0;  // alpha lica katrice mora biti na 0, zato jer kad se naličje bude okretalo, ne želimo vidjeti lice.
			LiceKartice.buttonMode = false;
			LiceKartice.x = 240;
			LiceKartice.y = 240;
			LiceKartice.IzadjiteIzZatvora.visible = true;
			LiceKartice.mouseChildren = false;
			NalicjeKartice.x = 240;
			NalicjeKartice.y = 240;
			NalicjeKartice.visible = true;
			NalicjeKartice.rotationY = 0;
			
			// potom puštamo zvuk naznake da će se otvoriti kartica sreće / državne blagajne
			var zvukNaznakeOtvaranja:karticaSreceOtvaranje_snd = new karticaSreceOtvaranje_snd();
			zvukNaznakeOtvaranja.play();
			
			// postavljamo tekst kartice sreće
			if (tipKartice == DRZAVNA_BLAGAJNA)
			{
				NalicjeKartice.gotoAndStop(1);  // frame s karticom državne blagajne
				InformacijeOKartici = DohvatiSljedecuKarticu(DRZAVNA_BLAGAJNA);
				LiceKartice.TipKartice.text = "DRŽAVNA BLAGAJNA";
			} else
			{
				NalicjeKartice.gotoAndStop(2);  // frame s karticom šanse
				InformacijeOKartici = DohvatiSljedecuKarticu(SANSA);
				LiceKartice.TipKartice.text = "ŠANSA";
			}
			LiceKartice.Tekst.text = InformacijeOKartici.TekstKartice;
			if (! InformacijeOKartici.IzadjiteIzZatvora)  // ako otvorena kartica nije kartica "Izađite iz zatvora, uklanjamo taj tekst s nje
				LiceKartice.IzadjiteIzZatvora.visible = false;
				
				
			// nakon što smo postavili sav tekst na karticu, matricu prikaza elemenata na kartici pohranjujemo u varijablu
			MatricaLicaKartice = LiceKartice.transform.matrix;
			
			// potom postavljamo animaciju (okretanje kartice) (još se neće pokrenuti, ovo je samo postavljanje)
			var animacija:TimelineMax = new TimelineMax( { paused:true, onComplete:UkloniKarticuSEkrana, onCompleteParams: [ tipKartice ] } );
			animacija.append(TweenMax.to(NalicjeKartice, BRZINA_OKRETANJA_KARTICE, { rotationY:90, visible:false, ease:Linear.easeNone } ));
			animacija.append(TweenMax.to(LiceKartice, 0, { alpha:1, rotationY:-90, immediateRender:false } ));
			animacija.append(TweenMax.to(LiceKartice, BRZINA_OKRETANJA_KARTICE, { rotationY:0, ease:Linear.easeNone } ));
			
			// postavljamo tajmer. kada tajmer istekne, animacija započinje
			var tajmer:Timer = new Timer(1000, 1);
			tajmer.addEventListener(TimerEvent.TIMER, ZapocniAnimaciju);
			tajmer.start();
			function ZapocniAnimaciju(e:TimerEvent):void
			{
				tajmer.stop();
				tajmer.removeEventListener(TimerEvent.TIMER, ZapocniAnimaciju);
				animacija.tweenTo(animacija.totalDuration);
				// i puštamo zvuk okretanja kartice sreće
				var zvukOkretanja:karticaSreceOkretanje_snd = new karticaSreceOkretanje_snd();
				zvukOkretanja.play();
			}
		}
		
		private function UkloniKarticuSEkrana(tipKartice:uint):void  // ovaj parametar nam nije zapravo potreban u ovoj funkciji, ali nam je potreban jer ga proslijeđujemo funkciji "Djeluj"
		{
			var tajmer:Timer = new Timer(2000, 1);
			
			// ako smo u ovoj funkciji, kartica se upravo okrenula! A to znači da je text blurran (što se moralo dogoditi jer TweenMax koristi rotationY). Kako bi ispravili blurrani tekst, na karticu primjenjujemo početnu matricu
			LiceKartice.transform.matrix = MatricaLicaKartice;
			
			// ako je igrač na potezu AI, dodajemo tajmer, koji će kada otkuca pozvati funkciju "Ukloni" koja će ukloniti karticu sa ekrana. U suprotnom, dodajemo click-listener na karticu
			if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
			{
				tajmer.addEventListener(TimerEvent.TIMER, Ukloni);
				tajmer.start();
			}
			else
			{
				LiceKartice.buttonMode = true;
				LiceKartice.addEventListener(MouseEvent.CLICK, Ukloni);
			}
			
			function Ukloni(e:Event = null):void
			{
				tajmer.stop();
				tajmer.removeEventListener(TimerEvent.TIMER, Ukloni);
				LiceKartice.removeEventListener(MouseEvent.CLICK, Ukloni);
				Monopoly.KontejnerIgre.removeChild(LiceKartice);
				Monopoly.KontejnerIgre.removeChild(NalicjeKartice);
				
				// djelujemo sukladno s onim što piše na kartici
				Djeluj(tipKartice);
			}
		}
		
		private function DohvatiSljedecuKarticu(tipKartice:uint):KarticaSrece
		{
			var kartica:KarticaSrece;
			
			if (tipKartice == DRZAVNA_BLAGAJNA)
			{
				kartica = TekstoviKarticaDrzavneBlagajne.pop();
				TekstoviKarticaDrzavneBlagajne.unshift(kartica);
				
			} else
			{
				kartica = TekstoviKarticaSanse.pop();
				TekstoviKarticaSanse.unshift(kartica);
			}
			
			return kartica;
		}
		
		private function Djeluj(tipKartice:uint):void
		{
			IgracNaPotezu = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
			if (tipKartice == DRZAVNA_BLAGAJNA)
			{
				switch (InformacijeOKartici.IndeksKartice)
				{
					case 0:  // ako se radi o kartici izađite iz zatvora, uklanjamo je iz polja kartica državne blagajne i dodjeljujemo igraču
						TekstoviKarticaDrzavneBlagajne.shift();
						var izadjiIzZatvora:karticaSrece_mc = new karticaSrece_mc();
						izadjiIzZatvora.gotoAndStop(3);
						izadjiIzZatvora.TipKartice.text = "DRŽAVNA BLAGAJNA";
						izadjiIzZatvora.IzadjiteIzZatvora.text = "IZAĐITE IZ ZATVORA";
						izadjiIzZatvora.Tekst.text = "Ova karta se može sačuvati dok\nse ne upotrijebi ili se može prodati.";
						IgracNaPotezu.KarticeIzadjiIzZatvora.push(izadjiIzZatvora);  // korisniku dodajemo karticu izađi iz zatvora
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 1:
						IgracNaPotezu.Novac += 400;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 2:		// idite na jeretovu ulicu
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNatragNaPolje(1);  
						break;
					case 3:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 2000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 4:
						IgracNaPotezu.Novac += 500;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 5:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 1000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 6:  // idite na kreni
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(0);  
						break;
					case 7:		// idite u zatvor
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.UZatvoru = new Zatvor();  // čim se instancira objekt tipa zatvor, pomiče igrača u zatvor
						IgracNaPotezu.UZatvoru.addEventListener("Izadji iz zatvora" + igrac_mc.IgracNaPotezu, IgracNaPotezu.IzadjiIzZatvora);
						IgracNaPotezu.addChild(IgracNaPotezu.UZatvoru);
						break;
					case 8:
						IgracNaPotezu.Novac += 2000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 9:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 1000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 10:	// rođendan vam je. uzmite 200 kuna od svakog igrača
						for (var i:uint = 0; i < igrac_mc.Igraci.length; i++)
						{
							if (igrac_mc.Igraci[i] != IgracNaPotezu)
							{
								igrac_mc.Igraci[i].ZadnjePlacanje = igrac_mc.Igraci.indexOf(IgracNaPotezu);
								igrac_mc.Igraci[i].Novac -= 200;
								IgracNaPotezu.Novac += 200;
							}
						}
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 11:
						IgracNaPotezu.Novac += 2000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 12:
						IgracNaPotezu.Novac += 200;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 13:	// platite 200 kuna ili uzmite karticu šanse
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						if (IgracNaPotezu.AIIgrac)
						{
							if (Math.random() < 0.5)
								KliknutoNaNovac();
							else
								KliknutoNaSansu();
						} else
						{
							Odabir = new dijalog_mc("Vaš Odabir?", 215, 290);
							Odabir.Prihvati.visible = false;
							Odabir.Odbij.visible = false;
							OdabirNovacIliSansa = new karticaSrece_mc();
							Odabir.DodajNaDijalog(OdabirNovacIliSansa, 4, 0, 20);
							Monopoly.KontejnerIgre.addChild(Odabir);
							
							if (IgracNaPotezu.Novac > 200) // ako igrač ima više od 200 kuna, dodat ćemo listener na novac (200 kuna). U suprotnom ćemo podesiti alpha kanal novca na 0.5
							{
								OdabirNovacIliSansa.Novac.addEventListener(MouseEvent.CLICK, KliknutoNaNovac);
								OdabirNovacIliSansa.Novac.buttonMode = true;
							} else
								OdabirNovacIliSansa.Novac.alpha = 0.5;
							OdabirNovacIliSansa.Sansa.addEventListener(MouseEvent.CLICK, KliknutoNaSansu);
							OdabirNovacIliSansa.Sansa.buttonMode = true;
						}
						break;
					case 14:
						IgracNaPotezu.Novac += 4000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 15:
						IgracNaPotezu.Novac += 1000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
				}
			} else
			{
				switch (InformacijeOKartici.IndeksKartice)
				{
					case 0:  // ako se radi o kartici izađite iz zatvora, uklanjamo je iz polja kartica šanse i dodjeljujemo igraču
						TekstoviKarticaDrzavneBlagajne.shift();
						izadjiIzZatvora = new karticaSrece_mc();
						izadjiIzZatvora.gotoAndStop(3);
						izadjiIzZatvora.TipKartice.text = "ŠANSA";
						izadjiIzZatvora.IzadjiteIzZatvora.text = "IZAĐITE IZ ZATVORA";
						izadjiIzZatvora.Tekst.text = "Ova karta se može sačuvati dok\nse ne upotrijebi ili se može prodati.";
						IgracNaPotezu.KarticeIzadjiIzZatvora.push(izadjiIzZatvora);  // korisniku dodajemo karticu izađi iz zatvora
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 1:
						IgracNaPotezu.Novac += 1000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 2:
						IgracNaPotezu.Novac += 2000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 3:		// idite do ilice
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(39);
						break;
					case 4:		// idite do riječkog glavnog kolodvora
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(15);
						break;
					case 5:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 400;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 6:		// idite na kreni
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(0);  
						break;
					case 7:		// idite u zatvor
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.UZatvoru = new Zatvor();  // čim se instancira objekt tipa zatvor, pomiče igrača u zatvor
						IgracNaPotezu.UZatvoru.addEventListener("Izadji iz zatvora" + igrac_mc.IgracNaPotezu, IgracNaPotezu.IzadjiIzZatvora);
						IgracNaPotezu.addChild(IgracNaPotezu.UZatvoru);
						break;
					case 8:		// idite na ulicu j.p.kamova
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(11);
						break;
					case 9:
						PlatiPoZgradi(800, 2300);
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 10:
						PlatiPoZgradi(500, 2000);
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 11:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 300;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 12:	// vratite se za 3 polja
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNatragNaPolje(IgracNaPotezu.Figurica.Pozicija - 3);
						break;
					case 13:
						IgracNaPotezu.ZadnjePlacanje = -1;
						IgracNaPotezu.Novac -= 3000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 14:
						IgracNaPotezu.Novac += 2000;
						if (IgracNaPotezu.Novac > 0)
							Monopoly.ZavrsiBacanje();
						break;
					case 15:	// idite na trg pučkih kapetana
						Monopoly.SakrijPokaziGumbZaKrajPoteza(false);
						IgracNaPotezu.IdiNaPolje(24);
						break;
				}
			}
		}
		
		private function PlatiPoZgradi(kuca:uint, hotel:uint):void
		{
			// ova funkcija služi samo za 2 kartice šanse: kada se za svaku kuću ili hotel koje igrač ima mora platiti određeni iznos
			// pretražujemo sva zemljišta i za ona koja su u vlasništvu igrača na potezu provjeravamo koliko imaju kuća / hotel, te prema tome smanjujemo igraču novac
			var zemljiste:Zemljiste;
			var zaPlatiti:uint = 0;
			for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
			{
				zemljiste = Zemljiste.Zemljista[i];
				if (zemljiste.Vlasnik == igrac_mc.IgracNaPotezu)
				{
					if (zemljiste.BrojKuca == 5)
						zaPlatiti += hotel;
					else	// ako je broj kuća 0, 1, 2, 3 ili 4
						zaPlatiti += zemljiste.BrojKuca * kuca;
				}
			}
			IgracNaPotezu.ZadnjePlacanje = -1;
			IgracNaPotezu.Novac -= zaPlatiti;
		}
		
		private function KliknutoNaNovac(e:MouseEvent = null):void
		{
			// ova funkcija će služiti samo za jednu karticu državne blagajne - kada možemo birati želimo li platiti 200 kuna ili uzeti karticu šanse
			if (! IgracNaPotezu.AIIgrac)
			{
				OdabirNovacIliSansa.Novac.removeEventListener(MouseEvent.CLICK, KliknutoNaNovac);
				OdabirNovacIliSansa.Sansa.removeEventListener(MouseEvent.CLICK, KliknutoNaSansu);
				Monopoly.KontejnerIgre.removeChild(Odabir);
				Odabir = null;
				OdabirNovacIliSansa = null;
				Monopoly.SakrijPokaziGumbZaKrajPoteza(true);
			}
			IgracNaPotezu.ZadnjePlacanje = -1;
			IgracNaPotezu.Novac -= 200;
			if (IgracNaPotezu.Novac > 0)
				Monopoly.ZavrsiBacanje();
		}
		
		private function KliknutoNaSansu(e:MouseEvent = null):void
		{
			// ova funkcija će služiti samo za jednu karticu državne blagajne - kada možemo birati želimo li platiti 200 kuna ili uzeti karticu šanse
			if (! IgracNaPotezu.AIIgrac)
			{
				OdabirNovacIliSansa.Novac.removeEventListener(MouseEvent.CLICK, KliknutoNaNovac);
				OdabirNovacIliSansa.Sansa.removeEventListener(MouseEvent.CLICK, KliknutoNaSansu);
				Monopoly.KontejnerIgre.removeChild(Odabir);
				Odabir = null;
				OdabirNovacIliSansa = null;
			}
			OtvoriKarticuSrece(SANSA);
		}
	}
}
