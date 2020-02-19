 export interface parameters{
    [index: string]: any;
    [index: number]: any;
}

export interface view{
    x: number;
    y: number;
    w: number;
    h: number;
    lock?: boolean;
    onChange?(): null;
}

export interface state{
    [index: string]: any;
    [index: number]: any;
}

interface HeliumElement{
    view: view;
    state: state;
    parameters: parameters;
    draw(x:number,y:number): null;
    undraw(): null;
}


export module helium{
    export let input: typeof import("./core/input") ;
}
export function helium<T>(chunk:(params:T,state:state,view:view)=>()=>void):(params:T, w:number, h:number)=>HeliumElement;