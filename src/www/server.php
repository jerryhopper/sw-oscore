#!/usr/bin/env php
<?php

declare(strict_types=1);


use Swoole\WebSocket\Server;
use Swoole\Http\Request;
use Swoole\WebSocket\Frame;



/*

discover|osbox
discover|osboxmaster

response :
command: discover|osbox
code: 200
msg: ok
data: {

}



 */



class discover {

    private $command;


    function __construct( Array $subcommands,pusher $pusher)
    {

        $this->pusher=$pusher;


        $this->method=$subcommands[0];
        $this->subcommands = $subcommands;



//        $this->pusher->push(  );

//        $this->SocketServer ->push($this->frame->fd, $this->result( $this->class->result() ) );

    }





    function result(){
        $cmd = $this->method;
        return $this->$cmd();
    }

    function osbox(){
        return ["OSBOX"];
    }

    function osboxmaster(){
        return "OSBOXMASTER";
    }
}




class commandProcess{

    private $statusCode = 500;
    private $statusMsg  = "Unknown error";


    function __construct(Frame $frame, Server $server, $pusher )
    {
        $this->SocketServer = $server;
        $this->frame = $frame;

        $this->command = $frame->data;

        echo "received message: {$frame->fd}\n";
        echo "received message: {$frame->data}\n";


        array( "frame"=>$frame, "sockertserver"=>$server);



        try{
            $this->command_exists($this->command);

        }catch( Exception $e){
            $x = $this->result($e->getMessage() );

            $this->pusher->push( "error", 500, $e->getMessage() );
            return;
        }



        $this->statusCode=200;
        $this->statusMsg="ok";

        //$r = $this->class;
        //$r->result();


        //$this->SocketServer ->push($this->frame->fd, $this->result( $this->class->result() ) );

        //$this->SocketServer ->push($frame->fd, $this->result( $this->class->result() ) );

    }




    function command_exists($command){
        $cmdparts = explode('|', $command);
        $class = "\\".$cmdparts[0];

        if( !class_exists($class) ){
            //echo "class '".$class."' doenst exist\n";
            $this->statusCode = 500;
            $this->statusMsg = "Invalid command";
            throw new Exception("Invalid command");
        }

        $subcommands = explode(" ", $cmdparts[1] );
        //echo "subcommands = ".json_encode($subcommands)."\n";

        $subcommand = $subcommands[0];
        //echo "> ".json_encode($subcommands )."\n";
        //echo " ". json_encode(get_class_methods($class) )."\n";
        echo "subcommand:".$subcommand."\n";


        if( ! in_array($subcommand,get_class_methods($class))  ){
            //echo "method ".$subcommand." doesnt exist.\n";
            $this->statusCode = 500;
            $this->statusMsg = "Invalid method";
            throw new Exception("Invalid method");
        }

        $this->class = new $class($subcommands,$this->SocketServer,$this->frame);

    }





    function result($data){


        //$data = 4;
        return $this->outputFormat( $data );
    }

    function outputFormat($data){
        return json_encode( [$this->statusCode, time(), array(
            "code"=>$this->statusCode,
            "msg"=>$this->statusMsg,
            "cmd"=>$this->command,
            "result"=>(object)$data )] );
    }
}













class pusher
{
    private $socketserver;
    private $frame;

    function __construct( Server $server,Frame $frame)
    {
        $this->socketserver = $server;
        $this->frame = $frame;
    }

    function push( $data , $statuscode=200,$statusmsg="ok"){
        $this->SocketServer ->push($this->frame->fd, $this->outputFormat( $data ) );
    }

    private function outputFormat($data, $statuscode,$statusmsg){
        return json_encode( [$this->statusCode, time(), array("result"=>(object)$data )] );
    }

}







$server = new Server("0.0.0.0", 9501);
$server->set(["worker_num" => 2]);

$server->on("start", function (Server $server) {
    echo "Swoole WebSocket Server is started at http://127.0.0.1:9502\n";
});

$server->on('open', function (Server $server, Swoole\Http\Request $request) {
    echo "connection open: {$request->fd}\n";
    $server->tick(1000, function () use ($server, $request) {
        $server->push($request->fd, json_encode(["noop", time()]));
    });
});

$server->on('message', function (Server $server, Frame $frame) {


    $pusher = new pusher($server,$frame);

    $pusher->push("YEEHAW");

    //$cp = new commandProcess($frame,$server,$pusher);

    //$cp = new commandProcess($frame->data);
    //$server->push($frame->fd, $cp->result() );
});

$server->on('close', function (Server $server, int $fd) {
    echo "connection close: {$fd}\n";
});

$server->start();
