package  {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.SoundChannel;
	
	public class kocka_mc extends MovieClip {
		private const MARGINA_NUTARNJEG_DIJELA_PLOCE:uint = 87;
		private static const DULJINA_STRANICE_PLOCE:uint = 480;
		private static var Monopoly:Igra;
		public var vektorSkaliranja:Number;
		public var xbrzina:Number, ybrzina:Number;
		public var faktorUsporavanja:Number;
		public static var Kocke:Array = new Array();
		private static var brojZaustavljenihKockica:uint;
		private static var ZvukKocki:Array = new Array();
		private static var ZvucniKanal:SoundChannel;

		public function kocka_mc() {
			ZvukKocki.push(new kockePad_snd());
			ZvukKocki.push(new kockeRoll_snd());
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			// prvi parent daje KontejnerIgre, drugi daje Kontejner, a tek treći daje objekt Igra
			Monopoly = this.parent.parent.parent as Igra;
			gotoAndStop(Math.floor(Math.random() * 6) + 1);
			
			for (var i:uint = 0; i < Kocke.length; i++)
			{
				// ako se radi o drugoj kocki, generirat ćemo x i y sve dok udaljenost između nje i prve kocke ne bude veća od 50px (time sprječavamo njihovo preklapanje)
				if (i == 1)
				{
					do
					{
						x = Math.random() * (480 - 2 * MARGINA_NUTARNJEG_DIJELA_PLOCE) + MARGINA_NUTARNJEG_DIJELA_PLOCE;
						y = Math.random() * (480 - 2 * MARGINA_NUTARNJEG_DIJELA_PLOCE) + MARGINA_NUTARNJEG_DIJELA_PLOCE;						
					} while (Monopoly.Udaljenost(Kocke[0].x, Kocke[0].y, Kocke[1].x, Kocke[1].y) < 100);
				} else
				{
					x = Math.random() * (480 - 2 * MARGINA_NUTARNJEG_DIJELA_PLOCE) + MARGINA_NUTARNJEG_DIJELA_PLOCE;
					y = Math.random() * (480 - 2 * MARGINA_NUTARNJEG_DIJELA_PLOCE) + MARGINA_NUTARNJEG_DIJELA_PLOCE;
				}
				
				rotation = Math.random() * 180;
			}
		}
		
		public static function BaciKockice(e:MouseEvent):void
		{
			const LOKACIJA_PRVE_KOCKICE:uint = 220; // X i Y
			const POCETNA_BRZINA_GIBANJA_KOCKICE:uint = 15;
			
			// kada se bace kocke, uklanjamo mogućnost da se iz zatvora izađe uporabom kartice i novca (ako je naravno igrač u zatvoru)
			var igracNaPotezu:igrac_mc = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
			if (igracNaPotezu.UZatvoru != null)
			{
				Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].KarticaZaIzlaz.alpha = 0.5;
				Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].KarticaZaIzlaz.removeEventListener(MouseEvent.CLICK, igracNaPotezu.UZatvoru.KliknutoNaKarticu);
				Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].NovacZaIzlaz.alpha = 0.5;
				Monopoly.UpravljackeIkone[Monopoly.IZADJI_IZ_ZATVORA_KONTROLE].NovacZaIzlaz.removeEventListener(MouseEvent.CLICK, igracNaPotezu.UZatvoru.KliknutoNaNovac);
			}
			
			// postavljamo broj zaustavljenih kockica na nulu
			brojZaustavljenihKockica = 0;
			
			// najprije moramo približiti jednu kockicu drugoj
			Kocke[0].x = LOKACIJA_PRVE_KOCKICE;
			Kocke[0].y = LOKACIJA_PRVE_KOCKICE;
			Kocke[1].x = DULJINA_STRANICE_PLOCE - LOKACIJA_PRVE_KOCKICE;
			Kocke[1].y = DULJINA_STRANICE_PLOCE - LOKACIJA_PRVE_KOCKICE;
			
			// zatim kockama pridijelimo neka svojstva. Vektor skaliranja ako je pozitivan označava povećavanje kockica, ako je negativan smanjivanje
			for (var i:uint = 0; i < Kocke.length; i++)
			{
				Kocke[i].vektorSkaliranja = 1;
				var smjerGibanja = Math.random() * 2 * Math.PI;
				Kocke[i].xbrzina = Math.cos(smjerGibanja) * POCETNA_BRZINA_GIBANJA_KOCKICE;
				Kocke[i].ybrzina = Math.sin(smjerGibanja) * POCETNA_BRZINA_GIBANJA_KOCKICE;
				// matematički izračun dobiven testiranjem (faktor usporavanja treba biti između 0.93 i 0.97)
				Kocke[i].faktorUsporavanja = Math.random() * 0.05 + 0.93;
				// s ovim simuliramo podizanje i spuštanje kockice prije nego što se zarotira (tj. bacanje same kockice prije njenog rotiranja)
				Kocke[i].addEventListener(Event.ENTER_FRAME, Kocke[i].SkalirajKockice);
				Kocke[i].addEventListener("Kockica stala", Kocke[i].KockicaStala);
			}
		}
		
		private function SkalirajKockice(e:Event):void
		{
			const POVECANJE_KOCKICE:Number = 0.09;
			var uvjet:Boolean;
			
			if (this.vektorSkaliranja == 1)
				uvjet = this.scaleX < 1.5;
			else
				uvjet = this.scaleX > 1;
				
			if (uvjet)
			{
				this.scaleX += POVECANJE_KOCKICE * this.vektorSkaliranja;
				this.scaleY += POVECANJE_KOCKICE * this.vektorSkaliranja;
			}
			else
			{
				if (this.vektorSkaliranja == 1)
					this.vektorSkaliranja = -1.3;
				else
				{
					e.currentTarget.removeEventListener(Event.ENTER_FRAME, SkalirajKockice);
					e.currentTarget.addEventListener(Event.ENTER_FRAME, RotirajKockice);
				}
			}
		}
		
		private function RotirajKockice(e:Event):void
		{
			const MINIMALNA_BRZINA:uint = 3;
			const SIGURNA_UDALJENOST:uint = 30;
			var kockica:kocka_mc = e.currentTarget as kocka_mc;
			var kutVektoraBrzine1:Number, kutVektoraBrzine2:Number;
			
			// najprije ćemo pustiti zvuk kocki (i to prvo zvuk pada, a nakon njega zvuk rotiranja kocke). I to samo pod uvjetom ako je zvučni kanal NULL. Ovo nam je potrebno jer bi u suprotnom obje kocke pustile zvuk, a to ne želimo
			if (ZvucniKanal == null)
			{
				ZvucniKanal = ZvukKocki[0].play();
				ZvucniKanal.addEventListener(Event.SOUND_COMPLETE, ReproducirajZvuk);
			}
			
			if (Math.abs(kockica.xbrzina) > MINIMALNA_BRZINA || Math.abs(kockica.ybrzina) > MINIMALNA_BRZINA)
			{
				kockica.x += kockica.xbrzina;
				kockica.y += kockica.ybrzina;
				
				// smanjujemo brzinu kocke
				kockica.xbrzina *= kockica.faktorUsporavanja;
				kockica.ybrzina *= kockica.faktorUsporavanja;
				kockica.gotoAndStop(Math.floor(Math.random() * 10) + 1);
				
				// ako kockica pobjegne lijevo
				if (kockica.x < MARGINA_NUTARNJEG_DIJELA_PLOCE)
				{
					kockica.x = MARGINA_NUTARNJEG_DIJELA_PLOCE;
					kockica.xbrzina *= -1;
				}
				
				// ako kockica pobjegne gore
				if (kockica.y < MARGINA_NUTARNJEG_DIJELA_PLOCE)
				{
					kockica.y = MARGINA_NUTARNJEG_DIJELA_PLOCE;
					kockica.ybrzina *= -1;
				}
				
				// ako kockica pobjegne desno
				if (kockica.x > DULJINA_STRANICE_PLOCE - MARGINA_NUTARNJEG_DIJELA_PLOCE)
				{
					kockica.x = DULJINA_STRANICE_PLOCE - MARGINA_NUTARNJEG_DIJELA_PLOCE;
					kockica.xbrzina *= -1;
				}
				
				// ako kockica pobjegne dolje
				if (kockica.y > DULJINA_STRANICE_PLOCE - MARGINA_NUTARNJEG_DIJELA_PLOCE)
				{
					kockica.y = DULJINA_STRANICE_PLOCE - MARGINA_NUTARNJEG_DIJELA_PLOCE;
					kockica.ybrzina *= -1;
				}
				
				if (Monopoly.Udaljenost(Kocke[0].x, Kocke[0].y, Kocke[1].x, Kocke[1].y) < SIGURNA_UDALJENOST)
				{
					// ako se kocke sudare, jedna će promijeniti smjer svog kraćeg vektora brzine, a druga će zamijenit svoje vektore smjera
					// prva kocka mijenja smjer kraćeg vektora brzine
					if (Kocke[0].xbrzina < Kocke[0].ybrzina)
						Kocke[0].xbrzina *= -1;
					else
						Kocke[0].ybrzina *= -1;
						
					// druga kocka mijenja oba vektora jedan s drugim
					var tmp:Number = Kocke[1].xbrzina;
					Kocke[1].xbrzina = Kocke[1].ybrzina;
					Kocke[1].ybrzina = tmp;
				}
			}
			else
			{
				// uklanjamo event listener s kockice koja stane i ona okida event "Kockica stala"
				kockica.removeEventListener(Event.ENTER_FRAME, RotirajKockice);
				kockica.dispatchEvent(new Event("Kockica stala"));
			}
		}
		
		private static var TESTPoljeSKockama:Array = new Array(1,1, 1,4);
		
		
		private function KockicaStala(e:Event):void
		{
			var kockica:kocka_mc = e.currentTarget as kocka_mc;
			
			e.currentTarget.removeEventListener("Kockica stala", KockicaStala);
			brojZaustavljenihKockica++;
			
			kockica.gotoAndStop(Math.floor(Math.random() * 6) + 1);
			//kockica.gotoAndStop(TESTPoljeSKockama[0]);
			//TESTPoljeSKockama.push(TESTPoljeSKockama.shift());
			
			if (brojZaustavljenihKockica == 2)
			{
				// prekidamo zvuk
				ZvucniKanal.stop();
				ZvucniKanal = null;
				
				// ako su obje kockice stale ...
				var igracNaPotezu:igrac_mc = igrac_mc.Igraci[igrac_mc.IgracNaPotezu];
				
				// okidamo event koji će reći da su kocke bačene
				igracNaPotezu.dispatchEvent(new Event("Kocke su stale", true));
				
				// ... i ako igrač nije u zatvoru, pomičemo figuricu igrača
				if (igracNaPotezu.UZatvoru == null) 
				{
					var figurica:figurica_mc = igracNaPotezu.Figurica;
					figurica.PomakniFiguricu(Kocke[0].currentFrame + Kocke[1].currentFrame);
				} else  // a ako igrač jest u zatvoru ...
				{
					// ... ako NIJE tek stigao u zatvor (polje s jednakim točkama u zadnja tri poteza nije prazno), smanjujemo preostali broj bacanja ...
					if (igracNaPotezu.IsteKockice.length != 0)
					{
						igracNaPotezu.UZatvoru.PreostaliBrojBacanja--;
						// ... i ako je preostali broj bacanja veći od nule, ispitujemo jesu li jednaki brojevi na kockama. U suprotnom (ako je broj bacanja == 0) on neće moći završiti potez dok ne plati (jer nije završio bacanje, pa ni ne može kliknuti na "end turn")
						if (igracNaPotezu.UZatvoru.PreostaliBrojBacanja > 0)
						{
							// ako kocke nisu iste, završavamo bacanje (jer ako jesu, okinut će se event iste kocke i bacanje će se tada okinuti. Ako su jednake, ovdje još ne smijemo završiti bacanje jer tada AI neće biti u mogućnosti pomaknuti figuricu
							if (Kocke[0].currentFrame != Kocke[1].currentFrame)
								Monopoly.ZavrsiBacanje();
						}
					}
				}
			}
		}
		
		private function ReproducirajZvuk(e:Event):void
		{
			ZvucniKanal = ZvukKocki[1].play();	// nakon što je zvuk padanja kocke stao, reproduciramo drugi zvuk u nizu - zvuk kotrljanja
			ZvucniKanal.removeEventListener(Event.SOUND_COMPLETE, ReproducirajZvuk);
		}
	}
}
