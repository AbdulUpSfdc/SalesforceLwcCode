const deepCopy = (o) => { if ( o ) return JSON.parse( JSON.stringify( o ) ); else return o; }

export class FieldsRegistry {

  registry;
  _currContext;
  _currField;

  _outOfContextDataFromRaisr;

  constructor() {
    this.registry = new Map();
    this._outOfContextDataFromRaisr = new Map(); // raisr fiedl type to { value: "", token: "" }
  }

  isFieldRegistered( context, name, type ) {
    let isReg = true;
    let flds = this.registry.get( context );
    if ( !flds ) {
      isReg = false;
    }
    else {
      const idx = flds.findIndex(fld=>fld.name === name);
      if ( idx >= 0 ) {
        isReg = true;
      }
      else {
        isReg = false;
      }
    }
    return isReg;
  }

  registerField( context, name, type ) {
    let flds = this.registry.get( context );
    if ( !flds ) {
      flds = [ { name: name, type: type } ];
      this.registry.set( context, flds );
    }
    else {
      const isRegistered = flds.find((el) => el.name === name);
      if ( !isRegistered ) {
        flds.push( { name: name, type: type } );
      }
    }
  }

  set currContext( context ) {
    this._currContext = context;
  }

  get currContext() {
    return this._currContext;
  }

  set currField( fieldName ) {
    this._currField = fieldName;
  }

  get currField() {
    return this._currField;
  }

  get currContextFields() {
    return deepCopy( this.registry.get( this.currContext ) );
  }

  unregisterField( context, name, type ) {
    let flds = this.registry.get( context );
    if ( flds ) {
      const trgIdx = flds.findIndex(el => el.name === name );
      if ( trgIdx >= 0 ) {
        flds.splice( trgIdx, 1 );
      }
      if ( flds.length === 0 ) {
        this.registry.delete( context );
      }
    }
  }

  findContext( context ) {
    return deepCopy( this.registry.get( context ) );
  }

  findFieldByName( context, name ) {
    let trgFld;
    let flds = this.registry.get( context );
    if ( flds ) {
      const trgIdx = flds.findIndex(el => el.name === name );
      if ( trgIdx >= 0 ) {
        trgFld = deepCopy( flds[ trgIdx ] );
      }
    }
    return trgFld;
  }

  findFieldByType( type ) {
    let trgFld;
    let flds = this.registry.get( this.currContext );
    if ( flds ) {
      const trgIdx = flds.findIndex(el => el.type === type );
      if ( trgIdx >= 0 ) {
        trgFld = deepCopy( flds[ trgIdx ] );
      }
    }
    return trgFld;
  } 

  addOutOfCtxtField( fieldType, value, token ) {
    this._outOfContextDataFromRaisr.set( fieldType, {
      fieldValue: value,
      token, token
    });
  }

  /*
   * @return { fieldType: type, fieldValue: value, token: token }
   */
  getAndCleanupOutOfCtxtField( fieldType ) {
    const fld = this._outOfContextDataFromRaisr.get( fieldType );
    let res;
    if (fld) {
      res = {
        fieldName: fieldType, // fiedlName not type since it is closer to the RAISR API
        fieldValue: fld.fieldValue,
        token: fld.token
      };
      this._outOfContextDataFromRaisr.delete( fieldType );
    }
    return res;
  }

  toString() {
    const reg = Object.fromEntries( this.registry );
    const outOfCtxt = Object.fromEntries( this._outOfContextDataFromRaisr );
    const res = {
      registry: reg,
      outOfCtxt: outOfCtxt
    };
    return JSON.stringify( res );
  }
}