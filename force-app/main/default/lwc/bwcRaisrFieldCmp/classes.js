export class CssClasses {

  constructor( css_classes_str ) {
    this.css = css_classes_str;
    this.parts = this.css.split( /\s+/ );
  }

  addClass( newClass ) {
    const idx = this.parts.findIndex( el => el === newClass );
    if ( idx < 0 ) {
      this.parts.push( newClass );
    }
    return this;
  }

  removeClasses( classToRemove ) {
    if ( !Array.isArray( classToRemove ) ) {
      classToRemove = [ classToRemove ];
    }
    this.parts = this.parts.filter( el => !classToRemove.includes( el ) );
    return this;
  }

  toString() {
    return this.parts.join( ' ' );
  }
}