package  {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.filters.GlowFilter;
	
	public class Igra extends Sprite {
		public const KOCKICE_GUMB:uint = 0;
		public const TRADE_GUMB:uint = 1;
		public const END_TURN_GUMB:uint = 2;
		public const IZADJI_IZ_ZATVORA_KONTROLE:uint = 3;
		public const DULJINA_STRANICE_PLOCE:uint = 480;
		private const MARGINA:uint = 20;
		public var Kontejner:Sprite = new Sprite();
		public var KontejnerIgre:Sprite = new Sprite();	// public jer u ovaj kontejner dodajemo sadržaj i iz drugih klasa
		private var SlikaPloce:Bitmap;
		public var UpravljackeIkone:Array = new Array();
		private var OznakeFigurica:Array;
		public var ProzirnaOznakaFigurice:ColorTransform = new ColorTransform();  // svakoj oznaki figurice ćemo dodati bijeli ili crni glow, kako bi se znalo koji je igrač trenutno na potezu
		public var CrnaOznakaFigurice:ColorTransform = new ColorTransform();
		public var PrikaziNovca:Array = new Array();
		public var FiguriceZaPrikaz:Vector.<figuricaOdabir_mc>;
		private var TipoviIgraca:Array;
		public var PoljaSrece:PoljeSrece = new PoljeSrece();
		private var Kvadrati:Vector.<Sprite> = new Vector.<Sprite>();  // nevidljivi kvadratići iznad svih polja
		public static var KockeBacene:Boolean = false;
		
		public function Igra(oznakeFigurica:Array, figuriceZaPrikaz:Vector.<figuricaOdabir_mc>, tipoviIgraca:Array) {	
			OznakeFigurica = oznakeFigurica;
			FiguriceZaPrikaz = figuriceZaPrikaz;
			TipoviIgraca = tipoviIgraca;
			PoljaSrece.Monopoly = this;
			dijalog_mc.Monopoly = this;
			ProzirnaOznakaFigurice.alphaMultiplier = 0;
			CrnaOznakaFigurice.color = 0x000000;
			
			this.addEventListener(Event.ADDED_TO_STAGE, PostaviIgru);
		}
		
		private function PostaviIgru(e:Event):void
		{
			this.addChild(Kontejner);			
			// u lokalni kontejner dodajemo kontejner igre koji će sadržavati ploču i sve što se nalazi na njoj
			Kontejner.addChild(KontejnerIgre);
			
			// dodavanje i resize-anje ploče
			var ploca:ploca_mc = new ploca_mc();
			var BitMapa:BitmapData = new BitmapData(ploca.width, ploca.height);
			BitMapa.draw(ploca);
			
			SlikaPloce = new Bitmap(BitMapa);
			SlikaPloce.smoothing = true;
			SlikaPloce.width = DULJINA_STRANICE_PLOCE - MARGINA;
			SlikaPloce.height = DULJINA_STRANICE_PLOCE - MARGINA;
			SlikaPloce.x += 10;
			SlikaPloce.y += 10;
			KontejnerIgre.addChild(SlikaPloce);
			
			
			// dodavanje pravokutnika na desnoj strani koji će koristiti kao sloj ispred ploče i iza ostalih objekata da se ne bi dogodilo da ploča prekrije upravljačke gumbe i ostale stvari na desnoj strani kad je zoomiramo
			var pravokutnik:Sprite = new Sprite();
			pravokutnik.graphics.beginFill(0xCCE3C7);	// svijetlo zelena (boja stage-a i monopoly ploče)
			pravokutnik.graphics.drawRect(DULJINA_STRANICE_PLOCE, 0, 640 - DULJINA_STRANICE_PLOCE, 480);
			pravokutnik.graphics.endFill();
			Kontejner.addChild(pravokutnik);
			
			// dodavanje upravljačkih gumbiju i ikona
			var BaciKocku_gumb:upravljackeIkone_mc = new upravljackeIkone_mc();
			BaciKocku_gumb.x = DULJINA_STRANICE_PLOCE + 2 * MARGINA;
			BaciKocku_gumb.y = DULJINA_STRANICE_PLOCE - MARGINA;
			UpravljackeIkone.push(BaciKocku_gumb);
			var Razmjena_gumb:upravljackeIkone_mc = new upravljackeIkone_mc();
			Razmjena_gumb.x = DULJINA_STRANICE_PLOCE + 4 * MARGINA;
			Razmjena_gumb.y = DULJINA_STRANICE_PLOCE - MARGINA;
			UpravljackeIkone.push(Razmjena_gumb);
			var EndTurn_gumb:upravljackeIkone_mc = new upravljackeIkone_mc();
			EndTurn_gumb.x = DULJINA_STRANICE_PLOCE + 6.2 * MARGINA;
			EndTurn_gumb.y = DULJINA_STRANICE_PLOCE - MARGINA;
			EndTurn_gumb.alpha = 0.5;
			UpravljackeIkone.push(EndTurn_gumb);
			var IzadjiIzZatvoraKontrole:upravljackeIkone_mc = new upravljackeIkone_mc();
			IzadjiIzZatvoraKontrole.x = Razmjena_gumb.x;
			IzadjiIzZatvoraKontrole.y = Razmjena_gumb.y - 70;
			IzadjiIzZatvoraKontrole.visible = false;	// ove kontrole neće biti vidljive sve dok igrač ne dođe u zatvor
			UpravljackeIkone.push(IzadjiIzZatvoraKontrole);
			
			for (var i:uint = 0; i < UpravljackeIkone.length; i++)
			{
				with (UpravljackeIkone[i])
				{
					Kontejner.addChild(UpravljackeIkone[i]);
					gotoAndStop(i + 1);
					if (UpravljackeIkone[i] != IzadjiIzZatvoraKontrole)	// za gumbe za izlaz iz zatvora nećemo dodati ova svojstva
					{
						buttonMode = true;
						addEventListener(MouseEvent.MOUSE_OVER, PromijeniVelcinuObjekta);
						addEventListener(MouseEvent.MOUSE_OUT, PromijeniVelcinuObjekta);
					} else  // nego dodajemo pojedinačno gumbima kontrole
					{
						IzadjiIzZatvoraKontrole.NovacZaIzlaz.buttonMode = true;
						IzadjiIzZatvoraKontrole.KarticaZaIzlaz.buttonMode = true;
					}
				}
			}
			
			// dodavanje kockica
			var kocka1:kocka_mc = new kocka_mc();
			kocka_mc.Kocke.push(kocka1);
			var kocka2:kocka_mc = new kocka_mc();
			kocka_mc.Kocke.push(kocka2);
			KontejnerIgre.addChild(kocka1);
			KontejnerIgre.addChild(kocka2);
			
			// dodavanje figurica i igrača u igru (figurica je grafički objekt, a igrač apstraktni). Figurica sadrži samo trenutnu poziciju, dok igrač sadrži sve ostalo
			IzmijesajRedosljedIgraca();
			var figurica:figurica_mc;
			var igrac:igrac_mc;
			
			for (i = 0; i < OznakeFigurica.length; i++)
			{
				// dodavanje igrača. U konstruktor unosimo figuricu. Oduzimamo broj jedan jer su figurice za prikaz (figuricaOdabir_mc) imale jedan početni prazni frame koji se nije odnosio ni na jednu figuricu
				if (TipoviIgraca[i] == "AI")
				{
					igrac = new AI(new figurica_mc(OznakeFigurica[i] - 1));
					igrac.AIIgrac = true;
				}
				else
				{
					igrac = new igrac_mc(new figurica_mc(OznakeFigurica[i] - 1));
					igrac.AIIgrac = false;
				}
				igrac_mc.Igraci.push(igrac);
				KontejnerIgre.addChild(igrac);
				// dodajemo figuricu za prikaz u gornji lijevi kut
				Kontejner.addChild(FiguriceZaPrikaz[i]);
				FiguriceZaPrikaz[i].x = 490 + (i % 2) * 85;
				FiguriceZaPrikaz[i].y = 15 + Math.floor(i / 2) * 120;
				FiguriceZaPrikaz[i].scaleX = 1.5;
				FiguriceZaPrikaz[i].scaleY = 1.5;
				FiguriceZaPrikaz[i].buttonMode = false;
				FiguriceZaPrikaz[i].Okvir.transform.colorTransform = (i == 0) ? CrnaOznakaFigurice : ProzirnaOznakaFigurice;
				PrikaziNovca.push(new upravljackeIkone_mc());
				Kontejner.addChild(PrikaziNovca[i]);
				PrikaziNovca[i].gotoAndStop(5 + i % 2);
				PrikaziNovca[i].x = 520 + (i % 2) * 80;
				PrikaziNovca[i].y = 100 + Math.floor(i / 2) * 118;
			}
			
			// dodavanje polja na ploču. Ovo će dodijeliti imena, indekse i ostala svojstva poljima na ploči
			// Budući da je ovaj dio jako dugačak i odnosi se na samu alokaciju i inicijalizaciju, omotat ćemo ga u funkciju
			InstancirajPoljaNaPloci();
			
			// ako je prvi igrač čovjek od krvi i mesa, dodat ćemo listener, u suprotnom ćemo samo bacit kockice
			var tkoIgraPrvi_dijalog:dijalog_mc = new dijalog_mc("Igrač \"" + igrac_mc.Igraci[0].Figurica.ImeFigurice + "\" igra prvi.");
			tkoIgraPrvi_dijalog.UkloniGumbX();
			KontejnerIgre.addChild(tkoIgraPrvi_dijalog);
			tkoIgraPrvi_dijalog.Prihvati.addEventListener(MouseEvent.CLICK, NaKlikPrihvati); 
			function NaKlikPrihvati (e:MouseEvent)
			{
				e.currentTarget.removeEventListener(MouseEvent.CLICK, NaKlikPrihvati); 
				KontejnerIgre.removeChild(e.currentTarget.parent);
				SakrijPokaziGumbZaKrajPoteza(false);
				
				if (TipoviIgraca[0] == "Osoba")
					BaciKocku_gumb.addEventListener(MouseEvent.CLICK, BaciKockice);
				else
				{
					SakrijPokaziTradeGumb(false);
					BaciKockice();
				}
			}
			
			// uklanjamo listener za ovu funkciju
			this.removeEventListener(Event.ADDED_TO_STAGE, PostaviIgru);
		}
		
		private function PromijeniVelcinuObjekta(e:MouseEvent):void
		{
			var objekt:MovieClip = e.currentTarget as MovieClip;
			
			if (e.type == MouseEvent.MOUSE_OVER)
			{
				objekt.scaleX = 1.3;
				objekt.scaleY = 1.3;
			} 
			else if (e.type == MouseEvent.MOUSE_OUT)
			{
				objekt.scaleX = 1;
				objekt.scaleY = 1;
			}
		}
		
		public function BaciKockice(e:MouseEvent=null):void
		{
			UpravljackeIkone[KOCKICE_GUMB].alpha = 0.5;
			UpravljackeIkone[END_TURN_GUMB].alpha = 0.5;
			// uklanjamo listener s gumba za bacanje kockica
			UpravljackeIkone[KOCKICE_GUMB].removeEventListener(MouseEvent.CLICK, BaciKockice);
			UpravljackeIkone[KOCKICE_GUMB].removeEventListener(MouseEvent.CLICK, ZavrsiPotez);
			
			KlikanjePoPlociOnOff(false);
				
			//pozivamo traženu statičku metodu
			KockeBacene = true;
			kocka_mc.BaciKockice(e);
		}
		
		public function Udaljenost(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			var x:Number = x1 - x2;
			var y:Number = y1 - y2;
			return Math.sqrt(x * x + y * y);
		}
		
		public function ZavrsiBacanje():void
		{
			var aiNaPotezu:Boolean = igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac;
			if (! aiNaPotezu)
				UpravljackeIkone[END_TURN_GUMB].alpha = 1;
			// ako igrač nije AI, dodajemo event listener na gumb za završavanje poteza. U suprotnom, završavamo tajmer na 500ms i tek onda završavamo potez.
			if (! aiNaPotezu)
				UpravljackeIkone[END_TURN_GUMB].addEventListener(MouseEvent.CLICK, ZavrsiPotez);
			else
			{
				var tajmer:Timer = new Timer(500, 1);
				tajmer.addEventListener(TimerEvent.TIMER, PozoviZavrsiPotez);
				tajmer.start();
				function PozoviZavrsiPotez(e:TimerEvent)
				{
					tajmer.removeEventListener(TimerEvent.TIMER, PozoviZavrsiPotez);
					tajmer.stop();
					ZavrsiPotez();
				}
				
			}
		}
		
		public function ZavrsiPotez(e:MouseEvent=null):void
		{
			var endTurn_gumb:upravljackeIkone_mc = UpravljackeIkone[END_TURN_GUMB];
			var igracNaPotezu:igrac_mc = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
			
			// ako igrač nije AI, znači da je morao kliknuti na gumb za završavanje poteza, pa zbog toga uklanjamo listener s tog gumba
			endTurn_gumb.alpha = 0.5;
			endTurn_gumb.removeEventListener(MouseEvent.CLICK, ZavrsiPotez);
				
			// uklanjamo prsten oko igrača (ako je instanciran)
			figurica_mc.BijeliPrsten.UkloniPrstenOkoIgraca();
			// promjene igrača
			if (igracNaPotezu.IsteKockice.length == 0 || igracNaPotezu.IsteKockice[igracNaPotezu.IsteKockice.length - 1] == false)
			{
				var tmpIgracNaPotezu:uint = igrac_mc.IgracNaPotezu;
				do {
					tmpIgracNaPotezu = (tmpIgracNaPotezu + 1) % igrac_mc.Igraci.length;
				} while (igrac_mc.Igraci[tmpIgracNaPotezu].Bankrotirao);  // pronalazimo sljedećeg igrača na potezu (uvjet je da nije bankrotirao)
				igrac_mc.IgracNaPotezu = tmpIgracNaPotezu;  // kad smo igrača pronašli, postavljamo ga na potez
				// varijablu igrač na potezu mijenjamo u novog igrača
				igracNaPotezu = igrac_mc.Igraci[tmpIgracNaPotezu];
				KockeBacene = false;
			}
			
			// ako je igrač u zatvoru (i nije AI), omogućit ćemo mu kontrole za izlazak iz zatvora
			if (igracNaPotezu.UZatvoru != null && ! igracNaPotezu.AIIgrac)
			{
				var izadjiIzZatvora:upravljackeIkone_mc = UpravljackeIkone[IZADJI_IZ_ZATVORA_KONTROLE];
				izadjiIzZatvora.visible = true;
				izadjiIzZatvora.NovacZaIzlaz.alpha = 1;
				izadjiIzZatvora.NovacZaIzlaz.addEventListener(MouseEvent.CLICK, igracNaPotezu.UZatvoru.KliknutoNaNovac);
				if (igracNaPotezu.KarticeIzadjiIzZatvora.length > 0)
				{
					izadjiIzZatvora.KarticaZaIzlaz.addEventListener(MouseEvent.CLICK, igracNaPotezu.UZatvoru.KliknutoNaKarticu);
					izadjiIzZatvora.KarticaZaIzlaz.alpha = 1;
				} else
				{
					izadjiIzZatvora.KarticaZaIzlaz.removeEventListener(MouseEvent.CLICK, igracNaPotezu.UZatvoru.KliknutoNaKarticu);
					izadjiIzZatvora.KarticaZaIzlaz.alpha = 0.5;
				}
			} else
			{
				UpravljackeIkone[IZADJI_IZ_ZATVORA_KONTROLE].visible = false;
			}
			
			// dodajemo prsten oko tog novog igrača (u kontejner, da bude iza trenutnog igrača)
			figurica_mc.BijeliPrsten = new prsten_mc (igracNaPotezu.Figurica.x, igracNaPotezu.Figurica.y);
			KontejnerIgre.addChildAt(figurica_mc.BijeliPrsten, KontejnerIgre.getChildIndex(igracNaPotezu));
			
			// dodaje se listener na gumb za bacanje kockica (ako igrac nije AI, tj. ako je čovjek).
			UpravljackeIkone[KOCKICE_GUMB].alpha = 1;
			if (! igracNaPotezu.AIIgrac)
			{
				UpravljackeIkone[KOCKICE_GUMB].addEventListener(MouseEvent.CLICK, BaciKockice);
				SakrijPokaziTradeGumb(true);
				KlikanjePoPlociOnOff(true);
			}
			else
			{
				KlikanjePoPlociOnOff(false);
				SakrijPokaziTradeGumb(false);
				// a ako jest AI, i nije u zatvoru, bacamo kockice. Ako jest u zatvoru, onda mu dajemo pravo da odluči što će sljedeće
				if (igracNaPotezu.UZatvoru != null)
					(igracNaPotezu as AI).OdlukaUZatvoru();
				else	// ako nije u zatvoru, odlučuje o kupovini kuća prije nego što baci kocke
				{
					(igracNaPotezu as AI).OdlukaOKupoviniZgrada();
					BaciKockice();
				}
			}
		}
		
		private function IzmijesajRedosljedIgraca():void
		{
			var nasumicniIndex:uint;
			var tmp1:uint, tmp2:String, tmp3:figuricaOdabir_mc;		// trebaju nam dvije privremene varijable jer ćemo izmiješati polje integera i polje tekstova
			
			for (var i:uint = OznakeFigurica.length - 1; i > 0; i--)
			{
				nasumicniIndex = Math.floor(Math.random() * (i + 1));
				
				// miješamo polje s oznakama figurica (integeri)
				tmp1 = OznakeFigurica[i];
				OznakeFigurica[i] = OznakeFigurica[nasumicniIndex];
				OznakeFigurica[nasumicniIndex] = tmp1;
				
				// miješamo polje s tipovima igrača (stringovi)
				tmp2 = TipoviIgraca[i];
				TipoviIgraca[i] = TipoviIgraca[nasumicniIndex];
				TipoviIgraca[nasumicniIndex] = tmp2;
				
				// miješamo polje s figuricama za prikaz igrača (grafički objekti)
				tmp3 = FiguriceZaPrikaz[i];
				FiguriceZaPrikaz[i] = FiguriceZaPrikaz[nasumicniIndex];
				FiguriceZaPrikaz[nasumicniIndex] = tmp3;
			}
		}
		
		public function SakrijPokaziGumbZaKrajPoteza(pokazi:Boolean):void
		{
			if (igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac == false)
			{
				if (pokazi)
				{
					UpravljackeIkone[END_TURN_GUMB].alpha = 1;
					UpravljackeIkone[END_TURN_GUMB].addEventListener(MouseEvent.CLICK, ZavrsiPotez);
				} else
				{
					UpravljackeIkone[END_TURN_GUMB].alpha = 0.5;
					UpravljackeIkone[END_TURN_GUMB].removeEventListener(MouseEvent.CLICK, ZavrsiPotez);
				}
			}
		}
		
		public function SakrijPokaziTradeGumb(pokazi:Boolean):void
		{
			if (pokazi && ! igrac_mc.Igraci[igrac_mc.IgracNaPotezu].AIIgrac)
			{
				UpravljackeIkone[TRADE_GUMB].alpha = 1;
				UpravljackeIkone[TRADE_GUMB].addEventListener(MouseEvent.CLICK, ZapocniRazmjenu);
			} else
			{
				UpravljackeIkone[TRADE_GUMB].alpha = 0.5;
				UpravljackeIkone[TRADE_GUMB].removeEventListener(MouseEvent.CLICK, ZapocniRazmjenu);
			}
		}
		
		public function KlikanjePoPlociOnOff(ukljuceno:Boolean):void
		{
			if (ukljuceno)
			{
				for (var i:uint = 0; i < Kvadrati.length; i++)
				{
					Kvadrati[i].buttonMode = true;
					Kvadrati[i].addEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
				}
			} else
			{
				for (i = 0; i < Kvadrati.length; i++)
				{
					Kvadrati[i].buttonMode = false;
					Kvadrati[i].removeEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
				}
			}
		}
		
		private function KliknutoNaPosjed(e:MouseEvent):void
		{
			// onemogućujemo daljnje klikanje po ploči (gasimo event listenere)
			KlikanjePoPlociOnOff(false);
			var indeksPolja:uint = Posjed.IndeksPoljaNaMjestuMisa(e.stageX, e.stageY);
			(Polje.Polja[indeksPolja] as Posjed).PrikaziDijalogPregledaPosjeda();
		}
		
		private function InstancirajPoljaNaPloci():void
		{
			Polje.Monopoly = this;
			
			Polje.Polja.push(new Polje("Kreni", 0, new Point(465.59, 407.44), Polje.KRENI_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Jeretova ulica", 1, new Point(406.16, 419.90), Polje.SMEDJE_POLJE, 1200, 40, 200, 600, 1800, 3200, 5000, 1000));
			Polje.Polja.push(Zemljiste.Zemljista[0]);
			
			Polje.Polja.push(new Polje("Državna blagajna", 2, new Point(369.42, 407.44), Polje.DRZAVNA_BLAGAJNA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Zagrebačka ulica", 3, new Point(332.36, 419.90), Polje.SMEDJE_POLJE, 1200, 80, 400, 1200, 3600, 6400, 9000, 1000));
			Polje.Polja.push(Zemljiste.Zemljista[1]);
			
			Polje.Polja.push(new Polje("Porez na dobit", 4, new Point(295.30, 407.44), Polje.POREZ_POLJE));
			
			ZeljeznickaStanica.ZeljeznickeStanice.push(new ZeljeznickaStanica("Zagrebački glavni kolodvor", 5, new Point(258.24, 407.44)));
			Polje.Polja.push(ZeljeznickaStanica.ZeljeznickeStanice[0]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Decumanus", 6, new Point(220.54, 419.90), Polje.SVIJETLO_PLAVO_POLJE, 2000, 120, 600, 1800, 5400, 8000, 11000, 1000));
			Polje.Polja.push(Zemljiste.Zemljista[2]);
			
			Polje.Polja.push(new Polje("Šansa", 7, new Point(183.80, 407.44), Polje.SANSA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Duga ulica", 8, new Point(146.74, 419.90), Polje.SVIJETLO_PLAVO_POLJE, 2000, 120, 600, 1800, 5400, 8000, 11000, 1000));
			Polje.Polja.push(Zemljiste.Zemljista[3]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Županijska ulica", 9, new Point(109.36, 419.90), Polje.SVIJETLO_PLAVO_POLJE, 2400, 160, 800, 2000, 6000, 9000, 12000, 1000));
			Polje.Polja.push(Zemljiste.Zemljista[4]);
			
			Polje.Polja.push(new Polje("U zatvoru", 10, new Point(72.61, 465.59), Polje.SLOBODNO_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Ulica J. P. Kamova", 11, new Point(59.84, 406.48), Polje.ROZNO_POLJE, 2800, 200, 1000, 3000, 9000, 12500, 15000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[5]);
			
			KomunalnaUstanova.KomunalneUstanove.push(new KomunalnaUstanova("Elektra", 12, new Point(72.61, 369.42)));
			Polje.Polja.push(KomunalnaUstanova.KomunalneUstanove[0]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Obala Lazareta", 13, new Point(59.84, 332.04), Polje.ROZNO_POLJE, 2800, 200, 1000, 3000, 9000, 12500, 15000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[6]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Maksimirska ulica", 14, new Point(59.84, 294.98), Polje.ROZNO_POLJE, 3200, 240, 1200, 3600, 10000, 14000, 18000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[7]);
			
			ZeljeznickaStanica.ZeljeznickeStanice.push(new ZeljeznickaStanica("Riječki željeznički kolodvor", 15, new Point(72.61, 257.92)));
			Polje.Polja.push(ZeljeznickaStanica.ZeljeznickeStanice[1]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Ulica S. Radića", 16, new Point(59.84, 220.54), Polje.NARANCASTO_POLJE, 3600, 280, 1400, 4000, 11000, 15000, 19000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[8]);
			
			Polje.Polja.push(new Polje("Državna blagajna", 17, new Point(72.61, 183.48), Polje.DRZAVNA_BLAGAJNA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Istarska ulica", 18, new Point(59.84, 146.42), Polje.NARANCASTO_POLJE, 3600, 280, 1400, 4000, 11000, 15000, 19000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[9]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Kapucinska ulica", 19, new Point(59.84, 109.04), Polje.NARANCASTO_POLJE, 4000, 320, 1600, 4400, 12000, 16000, 20000, 2000));
			Polje.Polja.push(Zemljiste.Zemljista[10]);
			
			Polje.Polja.push(new Polje("Besplatno parkiranje", 20, new Point(14.47, 71.98), Polje.SLOBODNO_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Zametska ulica", 21, new Point(73.58, 59.84), Polje.CRVENO_POLJE, 4400, 360, 1800, 5000, 14000, 17500, 21000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[11]);
			
			Polje.Polja.push(new Polje("Šansa", 22, new Point(110.64, 71.98), Polje.SANSA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Kalelarga", 23, new Point(147.70, 59.84), Polje.CRVENO_POLJE, 4400, 360, 1800, 5000, 14000, 17500, 21000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[12]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Trg pučkih kapetana", 24, new Point(184.76, 59.84), Polje.CRVENO_POLJE, 4800, 400, 2000, 6000, 15000, 18500, 22000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[13]);
			
			ZeljeznickaStanica.ZeljeznickeStanice.push(new ZeljeznickaStanica("Osječki glavni kolodvor", 25, new Point(221.82, 71.98)));
			Polje.Polja.push(ZeljeznickaStanica.ZeljeznickeStanice[2]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Forum", 26, new Point(259.52, 59.84), Polje.ZUTO_POLJE, 5200, 440, 2200, 6600, 16000, 19500, 23000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[14]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Trg kralja Tomislava", 27, new Point(296.26, 59.84), Polje.ZUTO_POLJE, 5200, 440, 2200, 6600, 16000, 19500, 23000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[15]);
			
			KomunalnaUstanova.KomunalneUstanove.push(new KomunalnaUstanova("Vodovod", 28, new Point(333.33, 71.98)));
			Polje.Polja.push(KomunalnaUstanova.KomunalneUstanove[1]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Zrinska ulica", 29, new Point(370.38, 59.84), Polje.ZUTO_POLJE, 5600, 480, 2400, 7200, 17000, 20500, 24000, 3000));
			Polje.Polja.push(Zemljiste.Zemljista[16]);
			
			Polje.Polja.push(new Polje("Idite u zatvor", 30, new Point(407.44, 14.47), Polje.IDITE_U_ZATVOR_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Trg bana Jelačića", 31, new Point(420.22, 73.58), Polje.ZELENO_POLJE, 6000, 520, 2600, 7800, 18000, 22000, 25500, 4000));
			Polje.Polja.push(Zemljiste.Zemljista[17]);
			
			Zemljiste.Zemljista.push(new Zemljiste("Korzo", 32, new Point(420.22, 110.64), Polje.ZELENO_POLJE, 6000, 520, 2600, 7800, 18000, 22000, 25500, 4000));
			Polje.Polja.push(Zemljiste.Zemljista[18]);
			
			Polje.Polja.push(new Polje("Državna blagajna", 33, new Point(407.44, 147.70), Polje.DRZAVNA_BLAGAJNA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Prokurativa", 34, new Point(420.22, 185.08), Polje.ZELENO_POLJE, 6400, 560, 3000, 9000, 20000, 24000, 28000, 4000));
			Polje.Polja.push(Zemljiste.Zemljista[19]);
			
			ZeljeznickaStanica.ZeljeznickeStanice.push(new ZeljeznickaStanica("Željeznička stanica Slavonski Brod", 35, new Point(407.44, 221.82)));
			Polje.Polja.push(ZeljeznickaStanica.ZeljeznickeStanice[3]);
			
			Polje.Polja.push(new Polje("Šansa", 36, new Point(407.44, 259.20), Polje.SANSA_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Stradun", 37, new Point(420.22, 296.26), Polje.TAMNO_PLAVO_POLJE, 7000, 700, 3500, 10000, 22000, 26000, 30000, 4000));
			Polje.Polja.push(Zemljiste.Zemljista[20]);
			
			Polje.Polja.push(new Polje("Super porez", 38, new Point(407.44, 333.32), Polje.POREZ_POLJE));
			
			Zemljiste.Zemljista.push(new Zemljiste("Ilica", 39, new Point(420.22, 370.38), Polje.TAMNO_PLAVO_POLJE, 8000, 1000, 4000, 12000, 28000, 34000, 40000, 4000));
			Polje.Polja.push(Zemljiste.Zemljista[21]);
			
			// kad smo popisali sva polja na ploči, postavljamo nevidljive kvadratiće na njih. Kada se klikne na taj kvadratić, otvarat će nam se dijalog s poljem na kojeg smo kliknuli, gdje će se moći kupiti / prodati zgrada ili podići / vratiti hipoteka
			// donja strana
			Kvadrati.push(new Sprite());
			Kvadrati[0].x = 370.53;
			Kvadrati.push(new Sprite());
			Kvadrati[1].x = 296.41;
			Kvadrati.push(new Sprite());
			Kvadrati[2].x = 221.65;
			Kvadrati.push(new Sprite());
			Kvadrati[3].x = 184.91;
			Kvadrati.push(new Sprite());
			Kvadrati[4].x = 110.47;
			Kvadrati.push(new Sprite());
			Kvadrati[5].x = 73.72;
			
			for (var i:uint = 0; i <= 5; i++)
			{
				KontejnerIgre.addChild(Kvadrati[i]);
				Kvadrati[i].graphics.beginFill(0x0, 0);
				Kvadrati[i].graphics.drawRect(0, 0, 36, 58.09);
				Kvadrati[i].graphics.endFill();
				Kvadrati[i].y = 407.44;
				Kvadrati[i].buttonMode = true;
				Kvadrati[i].addEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
			}
			
			
			// lijeva strana
			Kvadrati.push(new Sprite());
			Kvadrati[6].y = 370.53;
			Kvadrati.push(new Sprite());
			Kvadrati[7].y = 333.15;
			Kvadrati.push(new Sprite());
			Kvadrati[8].y = 296.09;
			Kvadrati.push(new Sprite());
			Kvadrati[9].y = 259.03;
			Kvadrati.push(new Sprite());
			Kvadrati[10].y = 221.65;
			Kvadrati.push(new Sprite());
			Kvadrati[11].y = 184.58;
			Kvadrati.push(new Sprite());
			Kvadrati[12].y = 110.15;
			Kvadrati.push(new Sprite());
			Kvadrati[13].y = 73.09;
			
			for (i = 6; i <= 13; i++)
			{
				KontejnerIgre.addChild(Kvadrati[i]);
				Kvadrati[i].graphics.beginFill(0x0, 0);
				Kvadrati[i].graphics.drawRect(0, 0, 58.14, 36);
				Kvadrati[i].graphics.endFill();
				Kvadrati[i].x = 14.47;
				Kvadrati[i].buttonMode = true;
				Kvadrati[i].addEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
			}
			
			
			// gornja strana
			Kvadrati.push(new Sprite());
			Kvadrati[14].x = 73.58;
			Kvadrati.push(new Sprite());
			Kvadrati[15].x = 147.70;
			Kvadrati.push(new Sprite());
			Kvadrati[16].x = 184.76;
			Kvadrati.push(new Sprite());
			Kvadrati[17].x = 221.82;
			Kvadrati.push(new Sprite());
			Kvadrati[18].x = 259.52;
			Kvadrati.push(new Sprite());
			Kvadrati[19].x = 296.26;
			Kvadrati.push(new Sprite());
			Kvadrati[20].x = 333.33;
			Kvadrati.push(new Sprite());
			Kvadrati[21].x = 370.38;
			
			for (i = 14; i <= 21; i++)
			{
				KontejnerIgre.addChild(Kvadrati[i]);
				Kvadrati[i].graphics.beginFill(0x0, 0);
				Kvadrati[i].graphics.drawRect(0, 0, 36, 58.09);
				Kvadrati[i].graphics.endFill();
				Kvadrati[i].y = 14.47;
				Kvadrati[i].buttonMode = true;
				Kvadrati[i].addEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
			}
			
			
			// desna strana
			Kvadrati.push(new Sprite());
			Kvadrati[22].y = 73.58;
			Kvadrati.push(new Sprite());
			Kvadrati[23].y = 110.64;
			Kvadrati.push(new Sprite());
			Kvadrati[24].y = 185.08;
			Kvadrati.push(new Sprite());
			Kvadrati[25].y = 221.82;
			Kvadrati.push(new Sprite());
			Kvadrati[26].y = 296.26;
			Kvadrati.push(new Sprite());
			Kvadrati[27].y = 370.38;
			
			for (i = 22; i <= 27; i++)
			{
				KontejnerIgre.addChild(Kvadrati[i]);
				Kvadrati[i].graphics.beginFill(0x0, 0);
				Kvadrati[i].graphics.drawRect(0, 0, 58.14, 36);
				Kvadrati[i].graphics.endFill();
				Kvadrati[i].x = 407.44;
				Kvadrati[i].buttonMode = true;
				Kvadrati[i].addEventListener(MouseEvent.CLICK, KliknutoNaPosjed);
			}
		}
		
		private function ZapocniRazmjenu(e:MouseEvent):void
		{
			var razmjena:razmjena_mc = new razmjena_mc(this);
		}
	}
}
