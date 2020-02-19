interface Subscription{
    on():void;
    off():void;
}

export enum inputType{
    clicked = "clicked",
    keypressed = "keypressed",
    hover = "hover",
    mousepressed = "mousepressed",
    mousereleased = "mousereleased",
    dragged = "dragged"
}

export function input(it:inputType,cb:(x?:number,y?:number)=>void,doff?:boolean,x?:number,y?:number,w?:number,h?:number): Subscription;