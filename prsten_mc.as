package  {
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	
	public class prsten_mc extends MovieClip {
		private var Monopoly:Igra;
		private var SmjerSkaliranja:Number;
		private var Xkoord:Number, Ykoord:Number;
		
		public function prsten_mc (xkoord:Number, ykoord:Number) {
			Xkoord = xkoord;
			Ykoord = ykoord;
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			
			Monopoly = this.parent.parent.parent as Igra;
			SmjerSkaliranja = 1;
			
			// dodajemo glow oko prstena
			var sjaj:GlowFilter = new GlowFilter(0xFFFFFF, 1, 6, 6, 2, 2);
			this.filters = new Array(sjaj);
			
			x = Xkoord;
			y = Ykoord;
			
			this.addEventListener(Event.ENTER_FRAME, SkalirajPrsten);
		}
		
		public function UkloniPrstenOkoIgraca():void
		{
			var uKontejneru:Boolean = false;
			
			// najprije provjeravamo jel se prsten nalazi u kontejneru (potrebno zbog dosad nepoznatog razloga)
			for (var i:uint = 0; i < Monopoly.KontejnerIgre.numChildren; i++)
				if (Monopoly.KontejnerIgre.getChildAt(i) == this)
					uKontejneru = true;
			
			// ako se prsten nalazi u kontejneru, uklanjamo ga iz njega
			if (uKontejneru)
				Monopoly.KontejnerIgre.removeChild(this);
			// u svakom ćemo slučaju ukloniti listener (ako ga nema, ovo se ignorira)
			this.removeEventListener(Event.ENTER_FRAME, SkalirajPrsten);
		}

		private function SkalirajPrsten(e:Event):void
		{
			const FAKTOR_SKALIRANJA:Number = 0.15;
			const MAX_SKALIRANJE:Number = 1.5;
			const MIN_SKALIRANJE:Number = 0.7;
			
			this.scaleX += FAKTOR_SKALIRANJA * SmjerSkaliranja;
			this.scaleY += FAKTOR_SKALIRANJA * SmjerSkaliranja;
			
			if (scaleX > MAX_SKALIRANJE || scaleX < MIN_SKALIRANJE)
				SmjerSkaliranja *= -1;
		}
	}
}
