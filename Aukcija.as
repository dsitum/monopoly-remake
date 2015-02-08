package  {
	import fl.accessibility.AccImpl;
	import fl.controls.TextInput;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class Aukcija {
		private var Monopoly:Igra;
		private var UkupanBrojAukcionara:uint = 0;  // inicijaliziramo taj broj na nulu, a kasnije ćemo ga promijeniti u broj igrača koji nisu bankrotirali
		private var _IndeksTrenutnogAukcionara:uint;
		private var PokretacAukcije:uint;
		private var TrenutniAukcionar:igrac_mc;
		private var IndeksPosjeda:uint;
		private var AukcionariKojiSuOdustali:Array = new Array();  // u ovo polje ćemo bilježiti indekse svih onih aukcionara koji su odustali
		private var DijalogAukcije:dijalog_mc;
		private var FiguriceAukcionara:Vector.<objektiZaInterakciju_mc> = new Vector.<objektiZaInterakciju_mc>();  // figurice za aukciju su tipa "objektiZaInterakciju_mc", a pod interakcijom se misli na interakciju igrača, što podrazumijeva aukciju i trade-anje
		private var PrikaziPonudaIgraca:Vector.<objektiZaInterakciju_mc> = new Vector.<objektiZaInterakciju_mc>();  // prikazi ponuda igrača su oni bijeli okvirići u kojima piše koliko je tko dao
		private var PonudaTextBox:TextInput;
		private var AukcijskiCekic:objektiZaInterakciju_mc;
		private var NajvisaPonuda:uint = 0;
		private var BijeliSjajFigurice:GlowFilter = new GlowFilter(0xFFFFFF, 1, 6, 6, 2, 2);  // svakoj figurici ćemo dodati bijeli ili crni glow, kako bi se raspoznavalo koja je figurica na aukciji
		private var CrniSjajFigurice:GlowFilter = new GlowFilter(0x000000, 0.5, 6, 6, 2, 2);
		private var GumbZaOdustajanje:objektiZaInterakciju_mc;
		
		public function Aukcija(monopoly:Igra, indeksPosjeda:uint) {
			PokretacAukcije = igrac_mc.IgracNaPotezu;
			IndeksPosjeda = indeksPosjeda;
			_IndeksTrenutnogAukcionara = (igrac_mc.IgracNaPotezu + 1) % igrac_mc.Igraci.length;
			TrenutniAukcionar = igrac_mc.Igraci[_IndeksTrenutnogAukcionara];
			Monopoly = monopoly;
			PripremiAukciju();
		}
		
		private function set IndeksTrenutnogAukcionara(noviIndeks:uint):void
		{
			// Uklanjamo bijeli glow sa starog aukcionara i postavljamo ga na novog
			FiguriceAukcionara[_IndeksTrenutnogAukcionara].filters = new Array(CrniSjajFigurice);
			FiguriceAukcionara[noviIndeks].filters = new Array(BijeliSjajFigurice);
			
			// ako aukcionar nije odustao, ažuriramo uneseni iznos u oblačić aukcionara
			if (AukcionariKojiSuOdustali.indexOf(_IndeksTrenutnogAukcionara) == -1)
			{
				// ako je trenutni igrač AI, iskoristit ćemo njegovu odluku. U suprotnom ćemo iskoristit iznos koji je korisnik unio
				if (TrenutniAukcionar.AIIgrac)
					PrikaziPonudaIgraca[_IndeksTrenutnogAukcionara].Tekst.text = (TrenutniAukcionar as AI).OdlukaOAukciji.toString() + " Kn";
				else
					PrikaziPonudaIgraca[_IndeksTrenutnogAukcionara].Tekst.text = NajvisaPonuda.toString() + " Kn";
			}
			
			// postavljamo novog aukcionara za trenutnog
			TrenutniAukcionar = igrac_mc.Igraci[noviIndeks];
			
			_IndeksTrenutnogAukcionara = noviIndeks;
			
			
			if (UkupanBrojAukcionara - AukcionariKojiSuOdustali.length > 1)
			{
				if (TrenutniAukcionar.AIIgrac)
				{
					// postavljamo status aukcionara (AI) u "Razmišljam"
					PrikaziPonudaIgraca[_IndeksTrenutnogAukcionara].Tekst.text = "Razmišljam ...";
					// dodajemo listener na event "Odluka donesena" koji će okinuti AI kad donese odluku
					(TrenutniAukcionar as AI).addEventListener("Odluka donesena", AiIzvrsiOdluku);
					// pozivamo funkciju koja će odlučiti o daljnoj aukciji AI-a
					(TrenutniAukcionar as AI).OdluciOAukciji(PokretacAukcije, IndeksTrenutnogAukcionara, NajvisaPonuda); 
				}
			}
		}
		
		private function get IndeksTrenutnogAukcionara():uint
		{
			return _IndeksTrenutnogAukcionara;
		}
		
		private function PripremiAukciju():void
		{
			var visinaDijaloga:uint;
			// ukupan broj aukcionara jednak je broju svih igrača koji nisu bankrotiarli
			for (var i:int = 0; i < igrac_mc.Igraci.length; i++)
				if (! igrac_mc.Igraci[i].Bankrotirao)
					UkupanBrojAukcionara++;
			var frameFigurice:uint;
			
			// ovisno o broju igrača (manje od 2, više od 2) će biti i visina dijaloga. Jer ako ima više igrača, morat ćemo ih nekako sve strpati u dijalog
			visinaDijaloga = 350 + Math.floor((UkupanBrojAukcionara - 1) / 2) * 100;
			DijalogAukcije = new dijalog_mc("", 320, visinaDijaloga);
			DijalogAukcije.UkloniGumbX();
			
			// postavljamo tekst Aukcija na sam vrh dijaloga
			DijalogAukcije.Tekst.text = "Aukcija: " + Polje.Polja[IndeksPosjeda].NazivPolja;
			DijalogAukcije.Tekst.width = 250;
			DijalogAukcije.Tekst.x -= 15;
			DijalogAukcije.Tekst.y = -0.5 * visinaDijaloga + 15;
			
			for (i = 0; i < UkupanBrojAukcionara; i++)
			{
				// postavljamo figurice na dijalog
				frameFigurice = igrac_mc.Igraci[i].Figurica.BrojFigurice;
				FiguriceAukcionara.push(new objektiZaInterakciju_mc());
				FiguriceAukcionara[i].filters = new Array(CrniSjajFigurice);
				if (visinaDijaloga == 350)
					DijalogAukcije.DodajNaDijalog(FiguriceAukcionara[i], frameFigurice, -100 + (i % 2) * 200, DijalogAukcije.Tekst.y + DijalogAukcije.Tekst.height / 2 + 100);
				else
					DijalogAukcije.DodajNaDijalog(FiguriceAukcionara[i], frameFigurice, -100 + (i % 2) * 200, DijalogAukcije.Tekst.y + DijalogAukcije.Tekst.height / 2 + 100 + Math.floor(i / 2) * 100);
				// postavljamo bijele okviriće s ponudom igrača na dijalog
				PrikaziPonudaIgraca.push(new objektiZaInterakciju_mc());
				DijalogAukcije.DodajNaDijalog(PrikaziPonudaIgraca[i], 11 + (i % 2), FiguriceAukcionara[i].x, FiguriceAukcionara[i].y - FiguriceAukcionara[i].height / 2 - 5);
			}
			
			// kraj teksta aukcije postavljamo čekić za aukciju
			AukcijskiCekic = new objektiZaInterakciju_mc();
			AukcijskiCekic.smjerRotacijeCekica = -1;
			DijalogAukcije.DodajNaDijalog(AukcijskiCekic, 15, 133, DijalogAukcije.Tekst.y + 15);
			// postavljamo textbox za unos ponude
			var unosPonude:objektiZaInterakciju_mc = new objektiZaInterakciju_mc();
			DijalogAukcije.DodajNaDijalog(unosPonude, 14, 0, visinaDijaloga / 2 - 35);
			unosPonude.Ponuda.addEventListener(Event.CHANGE, ProvjeriUneseniIznos);
			PonudaTextBox = unosPonude.Ponuda;
			// dodajemo gumb za odustajanje od aukcije
			GumbZaOdustajanje = new objektiZaInterakciju_mc();
			GumbZaOdustajanje.buttonMode = true;
			GumbZaOdustajanje.alpha = 0.5;
			DijalogAukcije.DodajNaDijalog(GumbZaOdustajanje, 13, -115, visinaDijaloga / 2 - 40);
			// postavljamo gumb za prihvaćanje unosa
			DijalogAukcije.Prihvati.alpha = 0.5;
			
			// ispod figurice aukcionara na potezu postavljamo bijeli glow
			FiguriceAukcionara[IndeksTrenutnogAukcionara].filters = new Array(BijeliSjajFigurice);
			// ako je igrač na potezu AI, dopuštamo mu da odluči koji će iznos staviti i isključujemo mogućnost unosa ponude u textbox
			if (TrenutniAukcionar.AIIgrac)
			{
				// postavljamo status aukcionara (AI) u "Razmišljam"
				PrikaziPonudaIgraca[_IndeksTrenutnogAukcionara].Tekst.text = "Razmišljam ...";
				// dodajemo listener na event "Odluka donesena" koji će okinuti AI kad donese odluku
				(TrenutniAukcionar as AI).addEventListener("Odluka donesena", AiIzvrsiOdluku);
				PonudaTextBox.enabled = false;
				(TrenutniAukcionar as AI).OdluciOAukciji(PokretacAukcije, IndeksTrenutnogAukcionara, NajvisaPonuda);
			}
				
			// prikazujemo dijalog aukcije
			Monopoly.KontejnerIgre.addChild(DijalogAukcije);
		}
		
		private function ProvjeriUneseniIznos(e:Event):void
		{
			var ponuda:TextInput = e.currentTarget as TextInput;
			if (parseInt(ponuda.text) < TrenutniAukcionar.Novac && parseInt(ponuda.text) > NajvisaPonuda)
			{
				DijalogAukcije.Prihvati.alpha = 1;
				DijalogAukcije.Prihvati.addEventListener(MouseEvent.CLICK, PonudiIznos);
			}
			else
			{
				DijalogAukcije.Prihvati.removeEventListener(MouseEvent.CLICK, PonudiIznos);
				DijalogAukcije.Prihvati.alpha = 0.5;
			}
		}
		
		private function PonudiIznos(e:MouseEvent = null):void
		{
			if (e == null)  // ako je ovaj uvjet ispunjen, znači da je AI upravo dao ponudu
				NajvisaPonuda = (TrenutniAukcionar as AI).OdlukaOAukciji;
			else
				NajvisaPonuda = parseInt(PonudaTextBox.text);  // u suprotnom postavljamo za najvišu ponudu trenutno unesenu
				
				
			// praznimo polje za unos iznosa
			PonudaTextBox.text = "";
			// postavljamo indeks trenutnog aukcionara na sljedeću vrijednost (ima setter)
			IndeksTrenutnogAukcionara = IndeksSljedecegAukcionara();
			// uklanjamo listener s gumba za prihvaćanje ponude
			DijalogAukcije.Prihvati.removeEventListener(MouseEvent.CLICK, PonudiIznos);
			DijalogAukcije.Prihvati.alpha = 0.5;
			// ako je novi trenutni aukcionar AI (a trenutni aukcionar se promijenio u sljedećeg u setteru), uklanjamo listenere s gumba za odustajanje od aukcije te onemogućujemo unos nove ponude
			if (TrenutniAukcionar.AIIgrac)
			{
				GumbZaOdustajanje.removeEventListener(MouseEvent.CLICK, OdustaniOdAukcije);
				GumbZaOdustajanje.alpha = 0.5;
				PonudaTextBox.enabled = false;
				// postavljamo za najvišu ponudu
			} else
			{
				// u suprotnom, dodajemo event listener, postavljamo vidiljvost gumba na 100% i omogućujemo unos ponude
				GumbZaOdustajanje.addEventListener(MouseEvent.CLICK, OdustaniOdAukcije);
				GumbZaOdustajanje.alpha = 1;
				PonudaTextBox.enabled = true;
			}
		}
		
		private function OdustaniOdAukcije(e:MouseEvent = null):void
		{
			// praznimo polje za unos iznosa
			PonudaTextBox.text = "";
			// U polje aukcionara koji su odustali bilježimo indeks trenutnog aukcionara
			AukcionariKojiSuOdustali.push(IndeksTrenutnogAukcionara);
			// U oblačić aukcionara koji je odustao upisujemo "Odustajem"
			PrikaziPonudaIgraca[IndeksTrenutnogAukcionara].Tekst.text = "Odustajem";
			// smanjujemo alpha kanal figurici onog igrača koji je odustao na 50%
			FiguriceAukcionara[IndeksTrenutnogAukcionara].alpha = 0.5;
			// postavljamo indeks trenutnog aukcionara na sljedeću vrijednost (ima setter)
			IndeksTrenutnogAukcionara = IndeksSljedecegAukcionara(); 
			if (UkupanBrojAukcionara - AukcionariKojiSuOdustali.length == 1)  // ako je preostao još jedan jedini aukcionar, aukcija je gotova i lupamo čekićem
			{
				// uklanjamo listenere sa svih gumbiju
				GumbZaOdustajanje.removeEventListener(MouseEvent.CLICK, OdustaniOdAukcije);
				GumbZaOdustajanje.alpha = 0.5;
				DijalogAukcije.Prihvati.removeEventListener(MouseEvent.CLICK, PonudiIznos);
				DijalogAukcije.Prihvati.alpha = 0.5;
				PonudaTextBox.enabled = false;
				AukcijskiCekic.Cekic.addEventListener(Event.ENTER_FRAME, LupiCekicom);
			}
		}
		
		private function IndeksSljedecegAukcionara():int
		{
			var tmpSljedeciIndeks:uint = IndeksTrenutnogAukcionara;
			// inkrementirat ćemo indeks trenutnog aukcionara (tj. njegovu tmp varijablu) sve dok se ne nađe neki indeks koji nije u polju onih aukcionara koji su odustali
			do
			{
				tmpSljedeciIndeks = (tmpSljedeciIndeks + 1) % igrac_mc.Igraci.length;
			} while (AukcionariKojiSuOdustali.indexOf(tmpSljedeciIndeks) != -1 || igrac_mc.Igraci[tmpSljedeciIndeks].Bankrotirao);
			
			return tmpSljedeciIndeks;
		}
		
		private function SkupiSmece():void
		{
			AukcijskiCekic.Cekic.removeEventListener(Event.ENTER_FRAME, LupiCekicom);
			PonudaTextBox.removeEventListener(Event.CHANGE, ProvjeriUneseniIznos);
			GumbZaOdustajanje.removeEventListener(MouseEvent.CLICK, OdustaniOdAukcije);
			DijalogAukcije.Prihvati.removeEventListener(MouseEvent.CLICK, PonudiIznos);
			Monopoly.KontejnerIgre.removeChild(DijalogAukcije);
			DijalogAukcije = null;
		}
		
		private function KupiPosjed():void
		{
			// postavljamo novog vlasnika za taj posjed (onog koji je dobio na aukciji)
			var posjed:Posjed = Polje.Polja[IndeksPosjeda] as Posjed;
			posjed.Vlasnik = IndeksTrenutnogAukcionara;
			// dobitniku aukcije ("TrenutniAukcionar") oduzimamo novac koji je platio za posjed
			TrenutniAukcionar.ZadnjePlacanje = -1;
			TrenutniAukcionar.Novac -= NajvisaPonuda;
			posjed.PostaviOznakuKupovine(TrenutniAukcionar, IndeksPosjeda);
			
			posjed.dispatchEvent(new Event("Posjed kupljen"));
			
		}
		
		private function AiIzvrsiOdluku(e:Event):void
		{
			// ova funkcija će izvršiti odluku AIa, nako što "razmisli" o odluci
			(TrenutniAukcionar as AI).removeEventListener("Odluka donesena", AiIzvrsiOdluku);
			
			if ((TrenutniAukcionar as AI).OdlukaOAukciji == -1)
				OdustaniOdAukcije();
			else
				PonudiIznos();
		}
		
		private function LupiCekicom(e:Event):void
		{
			const BRZINA_GIBANJA_CEKICA:uint = 6;
			
			// ako je smjer rotacije čekića prema dolje (-1) ...
			if (AukcijskiCekic.smjerRotacijeCekica == -1)
			{
				// ... svaki frame smanjujemo brzinu čekića za konstantu ...
				AukcijskiCekic.Cekic.rotation -= BRZINA_GIBANJA_CEKICA;
				// ... i ako je čekić pao (došao do kraja), mijenjamo njegov smjer rotacije (sada će ići natrag) i reproduciramo zvuk čekića
				if (AukcijskiCekic.Cekic.rotation <= -63) 
				{
					AukcijskiCekic.smjerRotacijeCekica *= -1;
					var zvukCekica:zvukCekica_snd = new zvukCekica_snd();
					zvukCekica.play();
				}
			} else
			{
				AukcijskiCekic.Cekic.rotation += BRZINA_GIBANJA_CEKICA / 2;
				if (AukcijskiCekic.Cekic.rotation > -1)
				{
					// nakon što se čekić vratio u početno stanje, uklanjamo sve listenere, dijalog, itd., a igrač koji je bio posljednji na potezu kupuje posjed za iznos koji je dao
					SkupiSmece();
					KupiPosjed();
				}
			}
		}
	}
}
