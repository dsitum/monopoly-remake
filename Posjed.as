package  {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import com.greensock.*;
	import com.greensock.easing.Linear;
	
	public class Posjed extends Polje {
		// VAŽNO!! iz ove klase se neće instancirati objekti, nego će ona služiti kao most između običnog polja i svih onih vrsta polja koje se mogu kupiti
		protected const NIJE_KUPLJENO:int = -1;
		public var Cijena:uint;
		protected var Najamnine:Array;	// najamnina označava iznos koji igrač mora platiti drugom igraču kada nagazi na njegovo zemljište. Imamo polje, zato jer postoji više najamnina (npr. najamnina samog zemljišta, najamnina s 3 kućice, najamnina s 2 komunalne ustanove, itd.)
		public var VrijednostHipoteke:uint;
		public var Vlasnik:int = NIJE_KUPLJENO; // "NIJE_KUPLJENO", ako nitko nije vlasnik. U suprotnom, sadržavat će indeks igrača vlasnika
		public var PodHipotekom:Boolean = false;
		public var KarticaPosjeda:karticaPosjeda_mc;
		public var KarticaHipoteke:karticaPosjeda_mc;
		protected var OznakaKupovine:Sprite;
		private var Dijalog:dijalogPregledaPosjeda_mc;
		
		public function Posjed(nazivPosjeda:String, indeksPosjeda:uint, koordinate:Point, vrstaPolja:uint, cijena:uint, najamnine:Array, vrijednostHipoteke:uint) {
			// budući da ova klasa neće imati objekata, a klasa koju je naslijedila ZAHTIJEVA konstruktor, mi moramo konstruktoru te nadređene klase poslati neke vrijednosti (nebitno koje)
			super(nazivPosjeda, indeksPosjeda, koordinate, vrstaPolja);
			Cijena = cijena;
			Najamnine = najamnine;
			VrijednostHipoteke = vrijednostHipoteke;
			KarticaHipoteke = IzradiKarticuHipoteke();
		}
	
		protected function KupiPosjed(nazivPosjeda:String, frame:uint):void
		{
			var trenutniIgrac:igrac_mc = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
			if (trenutniIgrac.AIIgrac)
			{
				var aiTrenutniIgrac:AI = trenutniIgrac as AI;	// radimo casting u objekt tipa AI (jer drukčije ne bi mogli prstupiti metodi "OdluciOKupovini"
				if (aiTrenutniIgrac.OdluciOKupovini())
					Kupi();
				else
					NemojKupiti();
			}
			else
			{
				// prije kupovine posjeda, najprije moramo pokazati dijalog koji će upitati korisnika želi li kupiti posjed
				var dijalog:dijalog_mc = new dijalog_mc("Želite li kupiti posjed \"" + nazivPosjeda + "\"?", 320, 430);
				dijalog.DodajNaDijalog(KarticaPosjeda, frame, 0, 50);
				Monopoly.KontejnerIgre.addChild(dijalog);
				dijalog.Odbij.addEventListener(MouseEvent.CLICK, NemojKupiti);
				if (trenutniIgrac.Novac > this.Cijena)
					dijalog.Prihvati.addEventListener(MouseEvent.CLICK, Kupi);
				else
					dijalog.Prihvati.alpha = 0.5;
			}
		}
		
		private function Kupi(e:MouseEvent=null):void
		{
			if (e != null)
			{
				var dijalog:dijalog_mc = e.currentTarget.parent as dijalog_mc;
				dijalog.Prihvati.removeEventListener(MouseEvent.CLICK, Kupi);
				dijalog.Odbij.removeEventListener(MouseEvent.CLICK, NemojKupiti);
				Monopoly.KontejnerIgre.removeChild(dijalog);
				dijalog = null;
			}
			
			this.Vlasnik = igrac_mc.IgracNaPotezu;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = -1;
			igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= this.Cijena;
			
			PostaviOznakuKupovine(igrac_mc.Igraci[igrac_mc.IgracNaPotezu]);
			
			this.dispatchEvent(new Event("Posjed kupljen"));
		}
		
		private function NemojKupiti(e:MouseEvent=null):void
		{
			if (e != null)
			{
				var dijalog:dijalog_mc = e.currentTarget.parent as dijalog_mc;
				dijalog.Prihvati.removeEventListener(MouseEvent.CLICK, Kupi);
				dijalog.Odbij.removeEventListener(MouseEvent.CLICK, NemojKupiti);
				Monopoly.KontejnerIgre.removeChild(dijalog);
				dijalog = null;
			}
			
			var aukcija:Aukcija = new Aukcija(Monopoly, igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Figurica.Pozicija);
		}
		
		public function PostaviOznakuKupovine(kupac:igrac_mc = null, indeksPosjeda:int = -1):void
		{
			// ova funkcija postavlja oznaku kupovine (u daljnjem tekstu dijamant) ispod posjeda na ploči
			var bojaDijamanta:uint;
			if (indeksPosjeda != -1)	// ako smo funkciji poslali argument indeksPosjeda (tj. različit je od -1), znači da želimo postaviti dijamant druge boje (nego što je trenutna) na određeno polje. To također znači da dijamant ondje već postoji, pa ga moramo i ukloniti
			{
				if (kupac == null)  	// ako nismo proslijedili kupca, znači da posjed ne prodajemo, nego dodajemo/uklanjamo sivi dijamant od hipoteke.
				{
					if ((Polja[indeksPosjeda] as Posjed).PodHipotekom)  // Ako je posjed pod hipotekom (upravo smo ga postavili), postavljamo boju dijamanta u sivu
						bojaDijamanta = 0xAAAAAA;	// svijetlo siva
					else  // ako posjed nije pod hipotekom (upravo smo je uklonili), boja dijamanta postaje boja vlasnika posjeda 
						bojaDijamanta = igrac_mc.Igraci[this.Vlasnik].Boja;
				} else	// ako smo funkciji proslijedili kupca (drugi vlasnik postaje vlasnikom ovog posjeda), boja dijamanta će biti boja toga vlasnika ili siva (u slučaju da je igrač bankrotirao, a posjed je bio pod hipotekom)
				{
					if ((Polja[indeksPosjeda] as Posjed).PodHipotekom)
						bojaDijamanta = 0xAAAAAA;
					else
						bojaDijamanta = kupac.Boja;
				}
			} else
			{
				bojaDijamanta = kupac.Boja;
			}
				
			// potreban nam je child objekt od dijamanta jer u suprotnom, da imamo samo dijamant, kada bi promijenili njegovu boju pa dodali bevel filter, taj filter se ne bi vidio. Stoga ćemo na sam dijamant primijeniti bevel, a na njegovo dijete stavit boju
			var oznakaKupovineDijete:oznakaKupovinePosjeda_mc = new oznakaKupovinePosjeda_mc();
			OznakaKupovine = new Sprite();
			oznakaKupovineDijete.stop();
			OznakaKupovine.addChild(oznakaKupovineDijete);
			Monopoly.KontejnerIgre.addChild(OznakaKupovine);
			
			// podešavamo "bevel" filter za dijamant
			var bevel:BevelFilter = new BevelFilter(5, 45, 0xFFFFFF, 1, bojaDijamanta, 1, 5, 5, 1, 1, "inner", false);
			// mijenjamo boju djetetu dijamanta u boju igrača koji je kupio posjed
			var uBojuIgraca:ColorTransform = new ColorTransform();
			uBojuIgraca.color = bojaDijamanta;
			oznakaKupovineDijete.transform.colorTransform = uBojuIgraca;
			
			// saznajemo lokaciju gdje dijamant treba postaviti
			var pozicija:Point = this.VratiSredinuPolja();  // pozicioniramo dijamant na sredinu polja. Jedna koordinata će valjati, a jedna neće (čitaj dalje)
			var stranaPloce = Math.floor(this.IndeksPolja / 10);  // strana ploče na kojoj se nalazi kupljeni posjed (potrebno za odrediti poziciju dijamanta)
			
			// budući da metoda "VratiSredinuPolja" vraća točku (objekt Point) između 2 polja, jedna od 2 koordinate će valjati, a jedna neće. Npr, ako se posjed nalazi dolje, x će valjati (jer će biti sredina izm 2 polja), a y ćemo morati korigirati (jer dijamant moramo spustiti skroz dolje), itd.
			// ako se polje nalazi lijevo ili desno ili gore, dijamant još moramo i promijeniti rotaciju dijamanta i rotaciju bevela (kako bi fini bevel efekt bio uvijek na nutarnjoj strani ploče)
			switch (stranaPloce)
			{
				case DOLJE: 
					pozicija.y = 475; 
					break;
				case LIJEVO: 
					pozicija.x = 5;
					bevel.angle += 90;
					OznakaKupovine.rotation += 90;
					break;
				case GORE: 
					pozicija.y = 5;
					bevel.angle += 180;
					OznakaKupovine.rotation = 180;
					break;
				case DESNO: 
					pozicija.x = 475;
					bevel.angle += 270;
					OznakaKupovine.rotation = -90; 
					break;
			}
			
			// najprije pokušavamo ukloniti dijamant na dobivenoj poziciji ako on već tamo postoji
			var postojeciDijamant:Sprite;
			for (var i:uint = 0; i < Monopoly.KontejnerIgre.numChildren; i++)
			{
				postojeciDijamant = Monopoly.KontejnerIgre.getChildAt(i) as Sprite;
				if (postojeciDijamant is Sprite)
					if (postojeciDijamant.name == "dijamant_" + pozicija.x.toString() + "_" + pozicija.y.toString())
						Monopoly.KontejnerIgre.removeChildAt(i);
			}
			
			// postavljamo dijamant na pronađenu poziciju
			OznakaKupovine.x = pozicija.x;
			OznakaKupovine.y = pozicija.y;
			// dodjeljujemo mu ime kako bi ga kasnije mogli lagano ukloniti ukoliko bude bilo potrebno
			OznakaKupovine.name = "dijamant_" + pozicija.x.toString() + "_" + pozicija.y.toString();
			// sada kad znamo rotaciju bevela, dodajemo ga na dijamant
			OznakaKupovine.filters = new Array(bevel);
		}
		
		public function PrikaziDijalogPregledaPosjeda():void  // ova funkcija se poziva kada korisnik klikne na neki posjed na ploči kako bi npr. kupio kuću ili podigao hipoteku
		{
			// stvaramo novi dijalog gdje ćemo dodati mogućnost kupnje zgrada
			Dijalog = new dijalogPregledaPosjeda_mc();
			Dijalog.x = 240;
			Dijalog.y = 240;
			Monopoly.KontejnerIgre.addChild(Dijalog);
			dijalog_mc.Prikazan = true;
			if (! this.PodHipotekom)
			{
				Dijalog.addChild(KarticaPosjeda);
				Dijalog.Hipoteka.gotoAndStop(1);
				KarticaPosjeda.x = 104.35;
				KarticaPosjeda.y = -13.60;
			} else
			{
				Dijalog.addChild(KarticaHipoteke);
				Dijalog.Hipoteka.gotoAndStop(2);
				KarticaHipoteke.x = 104.35;
				KarticaHipoteke.y = -13.60;
			}
			Dijalog.NazivPosjeda.text = NazivPolja;
			Dijalog.Objasnjenje.text = "";
			Dijalog.Hipoteka.alpha = 0.5;
			Dijalog.KucaGradi.alpha = 0.5;
			Dijalog.KucaRusi.alpha = 0.5;
			Dijalog.KucaGradi.gotoAndStop(3);
			Dijalog.KucaRusi.gotoAndStop(4);
			Dijalog.Povratak.gotoAndStop(7);
			Dijalog.Hipoteka.buttonMode = true;
			Dijalog.KucaGradi.buttonMode = true;
			Dijalog.KucaRusi.buttonMode = true;
			Dijalog.Povratak.buttonMode = true;
			Dijalog.Povratak.addEventListener(MouseEvent.CLICK, UgasiDijalog);
			
			if (igrac_mc.IgracNaPotezu != Vlasnik)  // ako igrač koji pregledava ovaj posjed nije vlasnik, neće moći kupiti / prodati kuću ili podići / vratiti hipoteku
			{
				if (this is Zemljiste)  
				{
					Dijalog.Objasnjenje.text = "Niste vlasnik ovog posjeda pa ne možete graditi kuće ni podizati hipoteke.";
				} else  // ako posjed nije zemljište, skrivamo gumbe za gradnju i rušenje kuća
				{
					Dijalog.Objasnjenje.text = "Niste vlasnik ovog posjeda pa ne možete podizati hipoteke.";
					Dijalog.KucaGradi.visible = false;
					Dijalog.KucaRusi.visible = false;
				}
			} else  // ali ako igrač jest vlasnik
			{
				Dijalog.Hipoteka.alpha = 1;  // omogućujemo mu rad s hipotekom
				Dijalog.Hipoteka.addEventListener(MouseEvent.CLICK, KlikNaHipoteku);
				
				if (this is Zemljiste)  // ako je posjed zemljište ...
				{
					var brojKuca = (this as Zemljiste).BrojKuca;
					
					if (brojKuca > 0)  // ako na zemljištu ima kuća, onemogućujemo podizanje hipoteke
					{
						Dijalog.Hipoteka.alpha = 0.5;
						Dijalog.Hipoteka.removeEventListener(MouseEvent.CLICK, KlikNaHipoteku);
						Dijalog.Objasnjenje.text = "Da biste mogli podići hipoteku, prodajte sve kuće na posjedu.";
					}
					
					if (brojKuca == 5)  // ako ima već izgrađeno pet kuća, dodat ćemo opciju samo za rušenje kuća (ne i za gradnju)
					{
						Dijalog.KucaGradi.gotoAndStop(5);
						Dijalog.KucaRusi.alpha = 1;
						Dijalog.KucaRusi.addEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
					}
					else if (brojKuca == 4)  // ako ima izgrađeno četiri kuće, dodat ćemo i opciju za izgradnju (ali Hotela, ne kuće!) i opciju za rušenje
					{
						Dijalog.KucaGradi.gotoAndStop(5);
						Dijalog.KucaGradi.alpha = 1;
						Dijalog.KucaGradi.addEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
						Dijalog.KucaRusi.alpha = 1;
						Dijalog.KucaRusi.addEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
					}
					else if (brojKuca <= 3 && brojKuca >= 1)  // ako ima izgrađeno između jedne i tri kuće, dodajemo opcije za izgradnju / rušenje kuća
					{
						Dijalog.KucaGradi.alpha = 1;
						Dijalog.KucaGradi.addEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
						Dijalog.KucaRusi.alpha = 1;
						Dijalog.KucaRusi.addEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
					}
					else  // a ako nije izgrađena nijedna kuća
					{
						var imaSvePosjedeIsteBoje:Boolean = true;
						for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
							if (VrstaPolja == Zemljiste.Zemljista[i].VrstaPolja && Zemljiste.Zemljista[i].Vlasnik != igrac_mc.IgracNaPotezu)
								imaSvePosjedeIsteBoje = false;
						
						if (! PodHipotekom && imaSvePosjedeIsteBoje) // ... i ako posjed nije pod hipotekom i vlasnik ima sve posjede iste boje, dodajemo opciju za igradnju kuće 
						{
							Dijalog.KucaGradi.alpha = 1;
							Dijalog.KucaGradi.addEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
						}
					}
				} else  // ako posjed nije zemljište, skrivamo gumbe za gradnju i rušenje kuća
				{
					Dijalog.KucaGradi.visible = false;
					Dijalog.KucaRusi.visible = false;
				}
			}
		}
		
		private function UgasiDijalog(e:MouseEvent):void
		{
			Dijalog.Hipoteka.removeEventListener(MouseEvent.CLICK, KlikNaHipoteku);
			Dijalog.KucaGradi.removeEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
			Dijalog.KucaRusi.removeEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
			Monopoly.KontejnerIgre.removeChild(Dijalog);
			dijalog_mc.Prikazan = false;
			Monopoly.KontejnerIgre.dispatchEvent(new Event("Dijalog zatvoren"));
			Dijalog = null;
			Monopoly.KlikanjePoPlociOnOff(true);
		}
		
		private function KlikNaHipoteku(e:MouseEvent):void
		{
			const BRZINA_OKRETANJA_KARTICE:Number = 0.3;
			var mogucePodiciHipoteku:Boolean = true;
			var animacija:TimelineMax;
			Dijalog.Objasnjenje.text = "";
			
			// hipoteke se ne mogu podizati ako na bilo kojem posjedu iste boje postoje kuće. Zato ćemo pretražiti sva zemljišta i provjeriti to
			if (this is Zemljiste)
			{
				var ovoZemljiste:Zemljiste = this as Zemljiste;
				for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
					if (Zemljiste.Zemljista[i].VrstaPolja == ovoZemljiste.VrstaPolja && Zemljiste.Zemljista[i].BrojKuca > 0)
						mogucePodiciHipoteku = false;
						
				if (! mogucePodiciHipoteku)
				{
					Dijalog.Objasnjenje.text = "Nije moguće podići hipoteku. Najprije prodajte zgrade na svim zemljištima ove boje.";
					return;
				}
			}
			
			// ako je moguće podići/vratiti hipoteku
			if (! this.PodHipotekom)
			{
				if (this is Zemljiste)
				{
					if ((this as Zemljiste).BrojKuca > 0)  // ako igrač želi podići hipoteku, a na zemljištu ima kuća
					{
						Dijalog.Objasnjenje.text = "Da biste mogli podići hipoteku, prodajte sve kuće na posjedu.";
						return;
					}
				}
				this.PodHipotekom = true;	// postavljamo hipoteku na posjed
				Dijalog.Hipoteka.gotoAndStop(2);	// mijenjamo gumb za podizanje hipoteke u gumb za vraćanje hipoteke
				Dijalog.addChildAt(KarticaHipoteke, Dijalog.getChildIndex(KarticaPosjeda));  // karticu hipoteke postavljamo iza kartice posjeda
				// postavljamo animaciju
				KarticaHipoteke.alpha = 0;
				KarticaHipoteke.visible = true;  // postavljamo karticu hipoteke vidljivom (jer je moguće da je nevidljiva, jer tweenmax ju postavi nevidiljivom nakon što završi s njom)
				animacija = new TimelineMax({onComplete: IzradiNovuKarticuHipoteke });
				animacija.append(TweenMax.to(KarticaPosjeda, BRZINA_OKRETANJA_KARTICE, { rotationY:90, visible:false, ease:Linear.easeNone } ));
				animacija.append(TweenMax.to(KarticaHipoteke, 0, { alpha:1, rotationY:-90, immediateRender:false } ));
				animacija.append(TweenMax.to(KarticaHipoteke, BRZINA_OKRETANJA_KARTICE, { rotationY:0, ease:Linear.easeNone } ));
				KarticaHipoteke.x = 104.35;
				KarticaHipoteke.y = -13.60;
				// uklanjamo listenere za gradnju i rušenje zgrada
				Dijalog.KucaGradi.alpha = 0.5;	
				Dijalog.KucaGradi.removeEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac += VrijednostHipoteke;
				PostaviOznakuKupovine(null, IndeksPolja);
			} else
			{
				// a ako već jest pod hipotekom
				if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac <= this.VrijednostHipoteke * 1.1)
				{
					// ako igrač nema dovoljno novca da vrati hipoteku, javljamo mu to porukom
					Dijalog.Objasnjenje.text = "Nemate dovoljno novca da bi vratili hipoteku.";
					return;
				}
				this.PodHipotekom = false;	// uklanjamo hipoteku s posjeda
				Dijalog.Hipoteka.gotoAndStop(1);	// mijenjamo gumb za vraćanje hipoteke u gumb za podizanje hipoteke
				// postavljamo animaciju
				KarticaPosjeda.alpha = 0;
				KarticaPosjeda.visible = true;  // postavljamo karticu posjeda vidljivom (jer je moguće da je nevidljiva, jer tweenmax ju postavi nevidiljivom nakon što završi s njom)
				Dijalog.addChildAt(KarticaPosjeda, Dijalog.getChildIndex(KarticaHipoteke));  // karticu posjeda postavljamo iza kartice posjeda
				animacija = new TimelineMax({ onComplete: IzradiNovuKarticuPosjeda });
				animacija.append(TweenMax.to(KarticaHipoteke, BRZINA_OKRETANJA_KARTICE, { rotationY:90, visible:false, ease:Linear.easeNone } ));
				animacija.append(TweenMax.to(KarticaPosjeda, 0, { alpha:1, rotationY:-90, immediateRender:false } ));
				animacija.append(TweenMax.to(KarticaPosjeda, BRZINA_OKRETANJA_KARTICE, { rotationY:0, ease:Linear.easeNone } ));				
				KarticaPosjeda.x = 104.35;
				KarticaPosjeda.y = -13.60;
				// dodajemo listenere za gradnju i rušenje zgrada (ako ima pravo na to)
				var imaSvePosjedeIsteBoje:Boolean = true;
				for (i = 0; i < Zemljiste.Zemljista.length; i++)
					if (VrstaPolja == Zemljiste.Zemljista[i].VrstaPolja && Zemljiste.Zemljista[i].Vlasnik != igrac_mc.IgracNaPotezu)
						imaSvePosjedeIsteBoje = false;
				
				if (imaSvePosjedeIsteBoje)
				{
					Dijalog.KucaGradi.alpha = 1;
					Dijalog.KucaGradi.addEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
				}
				
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = -1;
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= VrijednostHipoteke * 1.1;	// igrač plaća 10% više za vraćanje hipoteke
				PostaviOznakuKupovine(null, IndeksPolja);
				
				
			}
		}
		
		private function KlikNaGradiKucu(e:MouseEvent):void
		{
			const FRAME_S_KUPNJOM_HOTELA:uint = 5;
			var ovoZemljiste:Zemljiste = this as Zemljiste;
			var kucaSagradjena:Boolean;
			Dijalog.Objasnjenje.text = "";
			
			/// PRIJE GRADNJE
			// provjeravamo ima li igrač dovoljno novca za gradnju
			if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac <= (this as Zemljiste).CijenaKuce)
			{
				Dijalog.Objasnjenje.text = "Nemate dovoljno novca za gradnju na ovom zemljištu!";
				return;
			}
			
			// provjeravamo je li bilo koje od drugih zemljišta ove boje pod hipotekom. ako jest, neće biti moguće sadgraditi kuću
			for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
			{
				if (Zemljiste.Zemljista[i].VrstaPolja == ovoZemljiste.VrstaPolja && Zemljiste.Zemljista[i].PodHipotekom)
				{
					Dijalog.Objasnjenje.text = "Nije moguće graditi na ovom zemljištu. Najprije vratite hipoteke na svim posjedima ove boje.";
					return;
				}
			}
			
			// provjeravamo bi li gradnjom zgrade na ovom zemljištu gradnja na svim posjedima iste boje bila ravnomjerna. Ako ne bi, javljamo to porukom
			if (! ovoZemljiste.RavnomjernoIzgradjeneKuce(true))
			{
				Dijalog.Objasnjenje.text = "Nije moguće graditi na ovom zemljištu. Zgrade moraju biti građene ravnomjerno. Sagradite prvo kuću na drugom posjedu ove boje.";
				return;
			}
			
			// ako je broj kuća prije gradnje jednak 4, a NISU svi hoteli rasprodani, tada ćemo postavit hotel. U suprotnom, javljamo poruku da nema više hotela
			if (ovoZemljiste.BrojKuca == 4)
			{
				if (Zemljiste.UkupnoHotelaPreostalo > 0)
					kucaSagradjena = PostaviUkloniKucu(true);
				else
				{
					Dijalog.Objasnjenje.text = "Svi hoteli su rasprodani. Prodajte jedan od vaših hotela ili pričekajte da to učini drugi igrač.";
					return;
				}
			}
			else if (ovoZemljiste.BrojKuca < 4)  // ako je broj kuća prije gradnje manji od 4, a NISU sve kuće rasprodane, tada ćemo postavit kuću. U suprotnom, javljamo poruku da nema više kuća
			{
				if (Zemljiste.UkupnoKucaPreostalo > 0)
					kucaSagradjena = PostaviUkloniKucu(true);
				else
				{
					Dijalog.Objasnjenje.text = "Sve kuće su rasprodane. Prodajte jednu od vaših kuća ili pričekajte da to učini drugi igrač.";
					return;
				}
			}
			
			if (kucaSagradjena)
			{
				/// NAKON GRADNJE
				if (ovoZemljiste.BrojKuca == 4)  // ako zemljšite nakon gradnje ima već 4 kuće, tada ikonu za gradnju kuće mijenjamo u gradnju hotela
					Dijalog.KucaGradi.gotoAndStop(FRAME_S_KUPNJOM_HOTELA);
				if (ovoZemljiste.BrojKuca == 5)  // a ako zemljište nakon gradnje ima 5 kuća, uklanjamo listener s gumba za gradnju kuće
				{
					Dijalog.KucaGradi.removeEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
					Dijalog.KucaGradi.alpha = 0.5;
				}
				if (ovoZemljiste.BrojKuca == 1)  // ako smo upravo sagradili prvu kuću, dodajemo listener na gumb za rušenje kuće
				{
					Dijalog.KucaRusi.addEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
					Dijalog.KucaRusi.alpha = 1;
				}
				
				// uklanjamo listener s gumba za hipoteku
				Dijalog.Hipoteka.alpha = 0.5;
				Dijalog.Hipoteka.removeEventListener(MouseEvent.CLICK, KlikNaHipoteku);
			}
		}
		
		private function KlikNaRusiKucu(e:MouseEvent):void
		{
			const FRAME_S_KUPNJOM_KUCE:uint = 3;
			var ovoZemljiste:Zemljiste = this as Zemljiste;
			Dijalog.Objasnjenje.text = "";
			// ako je broj kuća nakon rušenja jednak četiri, dodaj listener na gradi hotel
			
			/// PRIJE GRADNJE
			// provjeravamo bi li rušenjem zgrade na ovom zemljištu izgrađene kuće na svim posjedima iste boje bile ravnomjerno raspoređene. Ako ne bi, javljamo to porukom
			if (! ovoZemljiste.RavnomjernoIzgradjeneKuce(false))
			{
				Dijalog.Objasnjenje.text = "Nije moguće prodavati zgrade na ovom zemljištu. Zgrade moraju biti postavljene ravnomjerno. Prodajte prvo kuću na drugom posjedu ove boje.";
				return;
			}
			
			// ako se na zemljištu trenutno nalazi hotel, i rušimo ga, provjeravamo ima li slobodno četiri kuće koje će zamijeniti taj hotel
			if (ovoZemljiste.BrojKuca == 5 && Zemljiste.UkupnoKucaPreostalo < 4)
			{
				Dijalog.Objasnjenje.text = "Nije moguće srušiti hotel u korist četiri kuće jer su sve kuće rasprodane. Prodajte četiri vaše kuće ili pričekajte da ih drugi igrači oslobode.";
				return;
			}
			
			PostaviUkloniKucu(false);  // ako su oba gornja uvjeta ispunjena, gradimo kuću
			
			/// NAKON GRADNJE
			if (ovoZemljiste.BrojKuca == 3)  // ako nakon rušenja preostaju 3 kuće, tada ikonu za gradnju kuće mijenjamo u ikonu za gradnju hotela
				Dijalog.KucaGradi.gotoAndStop(FRAME_S_KUPNJOM_KUCE);
			if (ovoZemljiste.BrojKuca == 4)  // ako nakon rušenja preostaju 4 kuće, dodajemo listener na gumb za gradnju hotela
			{
				Dijalog.KucaGradi.addEventListener(MouseEvent.CLICK, KlikNaGradiKucu);
				Dijalog.KucaGradi.alpha = 1;
			}
			if (ovoZemljiste.BrojKuca == 0)  // ako nakon rušenja nema više kuća, uklanjamo listener za rušenje kuće i dodajemo event listener za gradnju kuće
			{
				Dijalog.KucaRusi.removeEventListener(MouseEvent.CLICK, KlikNaRusiKucu);
				Dijalog.KucaRusi.alpha = 0.5;
				Dijalog.Hipoteka.addEventListener(MouseEvent.CLICK, KlikNaHipoteku);
				Dijalog.Hipoteka.alpha = 1;
			}
		}
		
		public static function IndeksPoljaNaMjestuMisa(xkoord:Number, ykoord:Number)
		{
			const DOLJE:uint = 0, LIJEVO:uint = 1, GORE:uint = 2, DESNO:uint = 3;
			var indeksPolja:uint;
			
			// pronalazimo posjed gdje je igrač kliknuo mišem
			// prvo pronalazimo stranu ploče na koju je igrač kliknuo
			var stranaPloce:uint;
			if (ykoord > 407.44)
				stranaPloce = DOLJE;
			else if (xkoord < 72.47)
				stranaPloce = LIJEVO;
			else if (ykoord < 72.47)
				stranaPloce = GORE;
			else  // if (xkoord > 407.44)
				stranaPloce = DESNO;
				
			// kada imamo stranu, pretražujemo dio polja Pôlja kako bi indeks polja gdje je igrač kliknuo
			switch (stranaPloce)
			{
				case DOLJE:
					for (var i:uint = 0; i < 10; i++)
					{
						if (xkoord > Polja[i + 1].Koordinate.x)
						{
							indeksPolja = i;
							break;
						}
					}
					break;
				case LIJEVO:
					for (i = 10; i < 20; i++)
					{
						if (ykoord > Polja[i + 1].Koordinate.y)
						{
						indeksPolja = i;
						break;
						}
					}
					break;
				case GORE:
					for (i = 20; i < 30; i++)
					{
						if (xkoord < Polja[i + 1].Koordinate.x)
						{
							indeksPolja = i;
							break;
						}
					}
					break;
				case DESNO:
					for (i = 30; i < 40; i++)
					{
						if (ykoord < Polja[(i + 1) % 40].Koordinate.y)
						{
							indeksPolja = i;
							break;
						}
					}
					break;
			}
			
			return indeksPolja;
		}
		
		private function IzradiKarticuHipoteke():karticaPosjeda_mc
		{
			const FRAME_S_HIPOTEKOM:uint = 5;
			var kartica:karticaPosjeda_mc = new karticaPosjeda_mc();
			kartica.gotoAndStop(FRAME_S_HIPOTEKOM);
			kartica.NazivPosjeda.text = NazivPolja.toUpperCase();
			kartica.VrijednostHipoteke.text = "Hipoteka " + VrijednostHipoteke.toString() + " Kn";
			kartica.mouseChildren = false;
			return kartica;
		}
		
		private function PostaviUkloniKucu(postavi:Boolean):Boolean
		{
			var ovoZemljiste:Zemljiste = this as Zemljiste;	
			var kuca:zgrada_mc, hotel:zgrada_mc;  // ove 2 varijable će nam koristiti za označavanje kuća i hotela koje budemo uklanjali sa stage-a
			
			if (postavi)  // ako gradimo novu zgradu
			{
				// kuće se ne smiju graditi ako je bilo koji posjed iste boje pod hipotekom. Zato ćemo pretražiti sva zemljišta i provjeriti to
				var moguceGraditi:Boolean = true;
				for (var i:uint = 0; i < Zemljiste.Zemljista.length; i++)
					if (Zemljiste.Zemljista[i].VrstaPolja == ovoZemljiste.VrstaPolja && Zemljiste.Zemljista[i].PodHipotekom)
						moguceGraditi = false;
						
				if (! moguceGraditi)
				{
					Dijalog.Objasnjenje.text = "Nije moguće graditi kuću jer je jer je jedan od posjeda ove boje pod hipotekom. Najprije vratite hipoteku toga posjeda.";
					return false;
				}
				
				// ako je moguće graditi (gornji uvjet ispunjen)
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].ZadnjePlacanje = -1;
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac -= ovoZemljiste.CijenaKuce;	// umanjujemo igraču novac za iznos jedne kuće
				ovoZemljiste.BrojKuca++;
				if (ovoZemljiste.BrojKuca == 5)  // ako nakon gradnje imamo 5 kuća (tj hotel)
				{
					Zemljiste.UkupnoHotelaPreostalo--;  // smanjujemo ukupni preostali broj hotela
					Zemljiste.UkupnoKucaPreostalo += 4;  // i povećavamo ukupni preostali broj kuća za 4 (jer smo s jednim hotelom oslobodili 4 kuće)
					
					// potom uklanjamo četiri postojeće kuće
					for (i = 1; i <= 4; i++)
					{
						kuca = Monopoly.KontejnerIgre.getChildByName("zgrada_" + ovoZemljiste.NazivPolja + i.toString()) as zgrada_mc;
						Monopoly.KontejnerIgre.removeChild(kuca);
					}
					// i gradimo novi hotel (na ploči)
					IzgradiNoviHotel();
				}
				else  // a ako nakon gradnje kuće imamo manje od 5 kuća
				{
					Zemljiste.UkupnoKucaPreostalo--;  // samo smanjujemo ukupni preostali broj kuća
					IzgradiNovuKucu(ovoZemljiste.BrojKuca);  // i gradimo novu kuću (na ploči)
				}
			} else  // ako uklanjamo postojeću zgradu
			{
				igrac_mc.Igraci[igrac_mc.IgracNaPotezu].Novac += 0.5 * ovoZemljiste.CijenaKuce;	// povećavamo igraču novac za iznos pola cijene kuće
				ovoZemljiste.BrojKuca--;
				if (ovoZemljiste.BrojKuca == 4)  // ako nakon rušenja imamo 4 kuće
				{
					Zemljiste.UkupnoHotelaPreostalo++;  // povećavamo ukupni broj hotela, jer smo umjesto jednog hotela postavili 4 kuće
					Zemljiste.UkupnoKucaPreostalo -= 4;  // smanjujemo broj kuća za četiri zbog gornjeg razloga
					
					// potom uklanjamo hotel
					hotel = Monopoly.KontejnerIgre.getChildByName("zgrada_" + ovoZemljiste.NazivPolja + "5") as zgrada_mc;
					Monopoly.KontejnerIgre.removeChild(hotel);
					
					// i gradimo nove 4 kuće
					for (i = 1; i <= 4; i++)
						IzgradiNovuKucu(i);
				}
				else  // a ako nakon rušenja imamo manje od 4 kuće
				{
					Zemljiste.UkupnoKucaPreostalo++;  // samo povećavamo broj kuća
					// i uklanjamo postojeću kuću
					kuca = Monopoly.KontejnerIgre.getChildByName("zgrada_" + ovoZemljiste.NazivPolja + (ovoZemljiste.BrojKuca + 1).toString()) as zgrada_mc;
					Monopoly.KontejnerIgre.removeChild(kuca);
				}
			}
			
			// ako je kuća sagrađena ili uklonjena (što jest ako smo došli od ovdje), metoda vraća true
			return true;
		}
		
		public function IzgradiNovuKucu(indeksKuce:uint):void
		{
			const FRAME_S_KUCOM:uint = 1;
			var ovoZemljiste:Zemljiste = this as Zemljiste;	
			var zgrada:zgrada_mc = new zgrada_mc();  // stvaramo novi objekt koji će reprezentirati zgradu na ploči
			zgrada.gotoAndStop(FRAME_S_KUCOM);
			// zgradu ćemo morati postaviti ispod dijaloga, tako da naprije tražimo ID dijaloga. I potom na mjesto tog ID-a postavljamo zgradu. Tako ćemo osigurati da ona bude ispod dijaloga
			if (Dijalog != null)  // a dijalog će biti null ako AI kupuje zgradu
			{
				var idDijaloga:int = Monopoly.KontejnerIgre.getChildIndex(Dijalog);
				Monopoly.KontejnerIgre.addChildAt(zgrada, idDijaloga);
			} else
			{
				Monopoly.KontejnerIgre.addChild(zgrada);
			}
			zgrada.name = "zgrada_" + ovoZemljiste.NazivPolja + indeksKuce.toString();  // zgradi dodjeljujemo ime kako bi je kasnije mogli ukloniti
			
			// potom gradimo kućicu
			var sirinaPolja:Number = VratiSirinuPolja();
			switch(Math.floor(IndeksPolja / 10))	// gdje ćemo postaviti kućicu ovisi o strani ploče na kojoj se posjed nalazi
			{
				case DOLJE:
					zgrada.x = this.Koordinate.x - (indeksKuce * 0.25 - 0.125) * sirinaPolja;  // na ovaj način svaku kuću postavljamo na sredinu njezine četvrtine
					zgrada.y = this.Koordinate.y - 6.23;
					break;
				case LIJEVO:
					zgrada.x = this.Koordinate.x + 6.23;
					zgrada.y = this.Koordinate.y - (indeksKuce * 0.25 - 0.125) * sirinaPolja;
					zgrada.rotation += 90;
					break;
				case GORE:
					zgrada.x = this.Koordinate.x + (indeksKuce * 0.25 - 0.125) * sirinaPolja;
					zgrada.y = this.Koordinate.y + 6.23;
					zgrada.rotation += 180;
					break;
				case DESNO:
					zgrada.x = this.Koordinate.x - 6.23;
					zgrada.y = this.Koordinate.y + (indeksKuce * 0.25 - 0.125) * sirinaPolja;
					zgrada.rotation += 270;
					break;
			}
		}
		
		public function IzgradiNoviHotel():void
		{
			const FRAME_S_HOTELOM:uint = 2;
			var ovoZemljiste:Zemljiste = this as Zemljiste;	
			var zgrada:zgrada_mc = new zgrada_mc();  // stvaramo novi objekt koji će reprezentirati zgradu na ploči
			zgrada.gotoAndStop(FRAME_S_HOTELOM);
			// zgradu ćemo morati postaviti ispod dijaloga, tako da naprije tražimo ID dijaloga. I potom na mjesto tog ID-a postavljamo zgradu. Tako ćemo osigurati da ona bude ispod dijaloga
			if (Dijalog != null)  // a dijalog će biti null ako AI kupuje zgradu
			{
				var idDijaloga:int = Monopoly.KontejnerIgre.getChildIndex(Dijalog);
				Monopoly.KontejnerIgre.addChildAt(zgrada, idDijaloga);
			} else
			{
				Monopoly.KontejnerIgre.addChild(zgrada);
			}
			zgrada.name = "zgrada_" + ovoZemljiste.NazivPolja + ovoZemljiste.BrojKuca.toString();  // zgradi dodjeljujemo ime kako bi je kasnije mogli ukloniti
			
			// potom gradimo hotel
			var sredinaPolja:Point = VratiSredinuPolja();
			switch(Math.floor(IndeksPolja / 10))  // gdje ćemo postaviti hotel ovisi o strani ploče na kojoj se posjed nalazi
			{
				case DOLJE:
					zgrada.x = sredinaPolja.x;
					zgrada.y = this.Koordinate.y - 6.23;
					break;
				case LIJEVO:
					zgrada.x = this.Koordinate.x + 6.23;
					zgrada.y = sredinaPolja.y;
					zgrada.rotation += 90;
					break;
				case GORE:
					zgrada.x = sredinaPolja.x;
					zgrada.y = this.Koordinate.y + 6.23;
					zgrada.rotation += 180;
					break;
				case DESNO:
					zgrada.x = this.Koordinate.x - 6.23;
					zgrada.y = sredinaPolja.y;
					zgrada.rotation += 270;
					break;
			}
		}
		
		public function IzradiNovuKarticuPosjeda():void
		{
			if (Dijalog != null)	// ako ovu metodu pozivamo iz druge klase, dijalog neće postojati!
				Dijalog.removeChild(KarticaPosjeda);
			// kako bi izbjegli blurranu karticu (što se događa pri 3d rotaciji u tweenmaxu), izrađujemo novu karticu posjeda nakon što se završi animacija
			if (this is Zemljiste)
				KarticaPosjeda = (this as Zemljiste).IzradiKarticuPosjeda();
			if (this is ZeljeznickaStanica)
				KarticaPosjeda = (this as ZeljeznickaStanica).IzradiKarticuPosjeda();
			if (this is KomunalnaUstanova)
				KarticaPosjeda = (this as KomunalnaUstanova).IzradiKarticuPosjeda();
			
			if (Dijalog != null)
				Dijalog.addChild(KarticaPosjeda);  // i dodajemo je na dijalog
			KarticaPosjeda.x = 104.35;
			KarticaPosjeda.y = -13.60;
		}
		
		private function IzradiNovuKarticuHipoteke():void  // ovu je funkciju bilo potrebno napraviti isključivo zbog tweenmaxa. 
		{
			if (Dijalog != null)
				Dijalog.removeChild(KarticaHipoteke);
			
			KarticaHipoteke = IzradiKarticuHipoteke();
			
			if (Dijalog != null)
				Dijalog.addChild(KarticaHipoteke);
				
			KarticaHipoteke.x = 104.35;
			KarticaHipoteke.y = -13.60;
		}
	}
}
