public class kt_flowURLName 
{
    @InvocableMethod(label='Remove Special Characters' description='Removes special characters from the Title for the URL Name')
    public static list<string> convertCharacters(list<string> titleText)
    {
        list<string> newText = new list<string>();
        datetime rightnow = datetime.now();
        // Creates a URL name based on the Article Title with special characters replaced with a hyphen and a timestamp suffix for uniqueness
        for (string currentTitle :titleText)
        {
            string tempTitle = currentTitle.replaceAll('[^[A-Za-z0-9]*$]', '-')+'-'+rightnow.hour()+rightnow.minute()+rightnow.second();
            integer count = 1;
            do 
            {
                if (tempTitle.startsWith('-'))
                {
                    tempTitle = tempTitle.removeStart('-'); 
                    count++;
                }
                else if (tempTitle.startsWith('$'))
                {
                    tempTitle = tempTitle.right(tempTitle.length()-1); 
                    count++;
                }
                else if (tempTitle.startsWith('*'))
                {
                    tempTitle = tempTitle.right(tempTitle.length()-1); 
                    count++;
                }
                else
                {
                    count = tempTitle.length();
                }
            } 
            while(count < tempTitle.length());
            
            newText.add(tempTitle); 
  //         newText.add(currentTitle.replaceAll('[^[A-Za-z0-9]*$]', '-')+'-'+rightnow.hour()+rightnow.minute()+rightnow.second()); 
        }
        return newText;
    }
}