interface Subscription{
    on():void;
    off():void;
}

export default function input(it:string,cb:(x?:number,y?:number)=>void,doff?:boolean,x?:number,y?:number,w?:number,h?:number): Subscription;