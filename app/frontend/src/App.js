import React, { useState } from 'react';
import styled from 'styled-components';

const Container = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 80vh; /* Increased height */
  background-color: #ffffff; /* Modern white background */
`;

const Form = styled.form`
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
`;

const Input = styled.input`
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 5px 0 0 5px;
  font-size: 16px;
  width: 250px;
  outline: none;
`;

const Button = styled.button`
  padding: 11px 20px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 0 5px 5px 0;
  cursor: pointer;
  font-size: 16px;
  margin-left: -1px;

  transition: background-color 0.3s ease;

  &:hover {
    background-color: #0056b3; /* Darker blue accent color */
  }
`;

const ResultInput = styled.input`
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 5px 0 0 5px;
  font-size: 16px;
  width: 250px;
  outline: none;
`;

const CopyButton = styled.button`
  padding: 11px 29.35px;
  background-color: #28a745; /* Green accent color */
  color: white;
  border: none;
  border-radius: 0 5px 5px 0;
  cursor: pointer;
  font-size: 16px;
  margin-left: -1px;
  transition: background-color 0.3s ease;

  &:hover {
    background-color: #218838; /* Darker green accent color */
  }
`;

const ResultContainer = styled.div`
  display: flex;
  align-items: center;
  margin-top: 10px; /* Added margin-top */
`;

const ErrorMessage = styled.span`
  color: red;
  font-size: 14px;
  margin-top: 5px;
`;

const CopyMessage = styled.span`
  color: black;
  font-size: 14px;
  margin-top: 5px;
`;

const App = () => {
  const [originalUrl, setOriginalUrl] = useState('');
  const [shortenedUrl, setShortenedUrl] = useState('');
  const [error, setError] = useState('');
  const [copied, setCopy] = useState('');

  const handleShortenUrl = async () => {
    try {
      const response = await fetch(process.env.REACT_APP_API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ originalUrl })
      });

      if (!response.ok) {
        throw new Error('Unable to shorten URL');
      }

      const data = await response.json();
      setShortenedUrl(data.shortenedUrl);
      setError('');
      setCopy('')
      
    } catch (error) {
      console.error('Error shortening URL:', error);
      setError('Error shortening URL. Please try again.');
      setShortenedUrl('');
      setCopy('')
    }
  };

  
  const handleCopy = () => {
    navigator.clipboard.writeText(shortenedUrl)
      .then(() => {
        setCopy("URL copied to clipboard!")
      })
      .catch((error) => {
        setError('Unable to copy to clipboard.');
        console.error('Unable to copy to clipboard.', error);
      });
  };

  return (
    <Container>
      <h1>URL Shortener</h1>
      <Form onSubmit={(e) => { e.preventDefault(); handleShortenUrl(); }}>
        <Input
          type="text"
          placeholder="Enter URL"
          value={originalUrl}
          onChange={(e) => setOriginalUrl(e.target.value)}
        />
        <Button type="submit">Shorten</Button>
      </Form>
      {shortenedUrl && <ResultContainer>
        <ResultInput
          type="text"
          placeholder="Shortened URL"
          readOnly
          value={shortenedUrl}
        />
        <CopyButton onClick={handleCopy}>Copy</CopyButton>
      </ResultContainer>}
      {error && <ErrorMessage>{error}</ErrorMessage>}
      {copied && <CopyMessage>{copied}</CopyMessage>}
    </Container>
  );
};
       
export default App;
