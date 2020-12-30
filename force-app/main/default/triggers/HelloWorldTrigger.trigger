trigger HelloWorldTrigger on Account (before insert) {
    system.debug('Hello World!');

}