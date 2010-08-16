/*
 The MIT License

 Copyright (c) 2010 Filipe Prata de Lima
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

package com.filipelima.soslogger
{
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.XMLSocket;

/**
 * This is a small helper Class to Log categorised messages to SOSmax.
 * @see http://www.sos.powerflasher.com
 * @see http://soenkerohde.com/2008/08/sos-logging-target/
 *
 * @author filipelima.com
 */
public class SOSlogger
{
    //    private static const TYPE_TRACE:String = "trace";   //light green
    private static const TYPE_DEBUG:String = "debug";   //blue
    private static const TYPE_INFO:String = "info";     //yellow
    private static const TYPE_WARN:String = "warn";     //orange
    private static const TYPE_ERROR:String = "error";   //red
    private static const TYPE_FATAL:String = "fatal";   //dark red
    private var _xmlSocket:XMLSocket;
    private static var _instance:SOSlogger;
    private var _history:Array;

    public function SOSlogger(singletonEnforcer:SingletonEnforcer)
    {
        connectXMLSocket();
    }

    /**
     * returns of the Socket is connected
     * @return Boolean
     */
    public function get isConnected():Boolean
    {
        return _xmlSocket.connected;
    }

    /**
     * Send a message of type INFO
     * @param message
     */
    public static function Info(message:*):void
    {
        Instance().sendMessage(TYPE_INFO, message.toString());
    }

    /**
     * Send a message of type DEBUG
     * @param message
     */
    public static function Debug(message:*):void
    {
        Instance().sendMessage(TYPE_DEBUG, message.toString());
    }

    /**
     * Send a message of type WARN
     * @param message
     */
    public static function Warn(message:*):void
    {
        Instance().sendMessage(TYPE_WARN, message.toString());
    }

    /**
     * Send a message of type ERROR
     * @param message
     */
    public static function Error(message:*):void
    {
        Instance().sendMessage(TYPE_ERROR, message.toString());
    }

    /**
     * Send a message of type FATAL
     * @param message
     */
    public static function Fatal(message:*):void
    {
        Instance().sendMessage(TYPE_FATAL, message.toString());
    }

    /**
     * Connect XMLSocket
     */
    private function connectXMLSocket():void
    {
        _history = [];

        _xmlSocket = new XMLSocket();
        _xmlSocket.addEventListener(Event.CONNECT, connectedHandler);
        _xmlSocket.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        _xmlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);

        try
        {
            _xmlSocket.connect("localhost", 4444);
        }
        catch(event:ErrorEvent)
        {
            trace("SecurityError in SOSlogger: " + event);
        }
    }

    /**
     * Handles Connection Successful to Socket
     * @param event
     */
    private function connectedHandler(event:Event):void
    {
        sendMessage(TYPE_INFO, "SOSlogger Successfully Connected on 'localhost:4444'");
    }

    /**
     * Handles connection Error to Sock
     * @param event
     */
    private function errorHandler(event:ErrorEvent):void
    {
        trace("Error in SOSlogger: " + event.text);
    }

    /**
     * Sends the message, if socket is not connected use normal Flash SOSlogger.getInstance().info()
     * @param type: level of priority of message
     * @param message: the message
     */
    private function sendMessage(type:String, message:String):void
    {
        var xmlMessage:XML;

        //seems some formatting needs more tinkering to get it right, lets just trace if fail.
        //all successfully filtered messages are put into a History list.

        /**
         * Filter for SOSmax
         */
        try
        {
            var sosMessage:String = message;
            sosMessage.replace("\n", "\r");
            sosMessage = "<![CDATA[" + sosMessage + "]]>";
            xmlMessage = < showMessage key={type} />;
            xmlMessage.appendChild(message);

            // if History becomes bigger then 500 messages flush it
            if (_history.length > 500)
            {
                _history = [];
            }

            _history.push(xmlMessage);
        }
        catch(e:ErrorEvent)
        {
            //send message to normal trace
            trace(message);
            sendMessage(TYPE_ERROR, "(  Failed to parse the previous message for SOSmax. )");
        }

        //if socket is not connected - send to normal trace
        if (!isConnected)
        {
            trace(message);
            return;
        }

        //reverse the order of saved messages
        _history.reverse();
        var i:uint = 0;
        for (; i < _history.length; i++)
        {
            _xmlSocket.send("!SOS" + ( _history.pop() as XML ).toXMLString() + "\r");
        }
    }

    /**
     * Returns the instance of this singleton
     * @return SOSlogger
     */
    private static function Instance():SOSlogger
    {
        if (!_instance)
        {
            _instance = new SOSlogger(new SingletonEnforcer());
        }
        return _instance;
    }
}
}

internal class SingletonEnforcer
{
}