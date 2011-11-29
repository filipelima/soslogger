package com.pixelplastik.logger
{
import flash.display.Sprite;
import flash.system.Security;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.XMLSocket;
import flash.system.System;

import spark.components.Application;

/**
 * This is a small helper Class to Log categorised messages to SOSmax.
 *
 * @author filipelima.com
 *
 * @see http://www.sos.powerflasher.com
 * @see http://soenkerohde.com/2008/08/sos-logging-target/
 */
public class SOSLogger extends Sprite
{
    private static const TYPE_TRACE:String = "trace";   //light green
    private static const TYPE_DEBUG:String = "debug";   //blue
    private static const TYPE_INFO:String = "info";     //yellow
    private static const TYPE_WARN:String = "warn";     //orange
    private static const TYPE_ERROR:String = "error";   //red
    private static const TYPE_FATAL:String = "fatal";   //dark red

    private var _xmlSocket:XMLSocket;

    private static var _instance:SOSLogger;

    private var _history:Array;

    public function SOSLogger( singletonEnforcer:SingletonEnforcer )
    {
        _history = [];

        //TODO: should check if its AIR to ignore this
//        Security.allowDomain( "localhost" );
		
        _xmlSocket = new XMLSocket();
        _xmlSocket.addEventListener( Event.CONNECT, connectedHandler );
        _xmlSocket.addEventListener( IOErrorEvent.IO_ERROR, errorHandler );
        _xmlSocket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, errorHandler );

        try
        {
            _xmlSocket.connect( "localhost", 4444 );
        }
        catch( event:* )
        {
            //trace( "SecurityError in SOSLogger: " + event );
        }
    }

    /**
     * Send a message of type INFO
     * @param message
     */
    public static function Info( message:* ):void
    {
        getInstance().sendMessage( TYPE_INFO, message.toString() );
    }

    /**
     * Send a message of type DEBUG
     * @param message
     */
    public static function Debug( message:* ):void
    {
        getInstance().sendMessage( TYPE_DEBUG, message.toString() );
    }

    /**
     * Send a message of type WARN
     * @param message
     */
    public static function Warn( message:* ):void
    {
        getInstance().sendMessage( TYPE_WARN, message.toString() );
    }

    /**
     * Send a message of type ERROR
     * @param message
     */
    public static function Error( message:* ):void
    {
        getInstance().sendMessage( TYPE_ERROR, message.toString() );
    }

    /**
     * Send a message of type FATAL
     * @param message
     */
    public static function Fatal( message:* ):void
    {
        getInstance().sendMessage( TYPE_FATAL, message.toString() );
    }

    /**
     * Returns the instance of this singleton
     * @return SOSLogger
     */
    protected static function getInstance():SOSLogger
    {
        if( !_instance )
        {
            _instance = new SOSLogger( new SingletonEnforcer() );
        }
        return _instance;
    }

    /**
     * returns of the Socket is connected
     * @return Boolean
     */
    protected function get isConnected():Boolean
    {
        return _xmlSocket.connected;
    }

    /**
     * Handles Connection Successful to Socket
     * @param event
     */
    protected function connectedHandler( event:Event ):void
    {
        sendMessage( TYPE_INFO, "SOSLogger Successfully Connected on 'localhost:4444'" );
    }

    /**
     * Handles connection Error to Sock
     * @param event
     */
    protected function errorHandler( event:ErrorEvent ):void
    {
        trace( "Error in SOSLogger: " + event.text );
    }

    /**
     * Sends the message, if socket is not connected use normal Flash SOSLogger.getInstance().info()
     * @param type: level of priority of message
     * @param message: the message
     */
    protected function sendMessage( type:String, message:String ):void
    {
		//if socket is not connected - send to normal trace
        if( !isConnected )
        {
            trace( message );
            return;
        }

        //seems some formatting needs more tinkering to get it right, lets just trace if fail.
        //all successfully filtered messages are put into a History list.

        /**
         * Filter for SOSmax
         */
		var xmlMessage:XML;
		
        try
        {
            var sosMessage:String = message;
            sosMessage.replace( "\n", "\r" );
            sosMessage = "<![CDATA[" + sosMessage + "]]>";
            xmlMessage = < showMessage key={type} />;
            xmlMessage.appendChild( message );

            // if History becomes bigger then 500 messages flush it
            if( _history.length > 500 )
            {
                _history = [];
            }

            _history.push( xmlMessage );
        }
        catch( e:* )
        {
            //send message to normal trace
            trace( message );
            sendMessage( TYPE_ERROR, "(  Failed to parse the previous message for SOSmax. )" );
        }

        //reverse the order of saved messages
        _history.reverse();
        var i:uint = 0;
        for( ; i < _history.length; i++ )
        {
            _xmlSocket.send( "!SOS" + ( _history.pop() as XML ).toXMLString() + "\r" );
        }
    }
}
}

internal class SingletonEnforcer
{
}