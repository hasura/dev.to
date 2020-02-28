import { h, render } from 'preact';
import gql from 'graphql-tag';
import { ApolloProvider } from 'react-apollo';
import { Article, Feed, LoadingArticle } from '../articles';
// import { FeaturedArticle } from '../articles/FeaturedArticle';

// TODO: why is icon broken without this?
const COMMENTS_ICON = '/assets/comments-bubble.png';

/**
 * Renders the main feed.
 */
export const renderFeed = client => {
  // the client itself is working fine
  client
    .query({
      query: gql`
        {
          articles(where: { id: { _eq: 1 } }) {
            comments_count
          }
        }
      `,
    })
    .then(result => console.log(result));

  const feedContainer = document.getElementById('homepage-feed');

  render(
    // the feed doesn't load with ApolloProvider
    <ApolloProvider client={client}>
      <Feed
        renderFeedItems={(feedItems = []) => {
          if (feedItems.length === 0) {
            // Fancy loading ✨
            return (
              <div>
                <LoadingArticle />
                <LoadingArticle />
                <LoadingArticle />
              </div>
            );
          }

          // const [featuredStory, ...subStories] = feedItems;
          const [...subStories] = feedItems;

          // 1. Show the featured story first
          // 2. Podcast episodes out today
          // 3. Rest of the stories for the feed
          return (
            <div>
              {
                // <FeaturedArticle article={featuredStory} />
                // <div id="article-index-podcast-div">PODCAST EPISODES</div>
              }
              {(subStories || []).map(story => {
                if (story.id === 1) {
                  return (
                    <Article article={story} commentsIcon={COMMENTS_ICON} />
                  );
                }
                return null;
              })}
            </div>
          );
        }}
      />
    </ApolloProvider>,
    feedContainer,
    feedContainer.firstElementChild,
  );
};
